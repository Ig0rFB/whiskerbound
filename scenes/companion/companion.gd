@tool
extends GroundedCharacter
## Lumi — cat companion follow via A* (PROJECT.md §9.2).

@onready var _visual: Node3D = $Visual
@onready var _model: Node3D = $Visual/Model
@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D

var _data := CompanionData.new()
var _feet_collider: Rect2 = CompanionCollider.feet_rect()
var _slot: int = 0
var _anim: AnimationPlayer
var _last_feet: Vector2 = Vector2.ZERO
var _model_fitted := false
var _editor_snapping := false
var _nav_goal_timer: float = 0.0
## Unit "behind the player" direction, refreshed while the player moves; held while idle.
var _back_dir: Vector2 = Vector2.ZERO
## Per-companion formation, set once at spawn: fanned slot angle plus random jitter so cats spread.
var _formation_angle: float = 0.0
var _formation_distance_jitter: float = 0.0


func _ready() -> void:
	body_radius = Config.COMPANION_BODY_RADIUS
	body_height = Config.COMPANION_BODY_HEIGHT
	if Engine.is_editor_hint():
		_apply_body_defaults()
		_ensure_collision_shape()
		set_physics_process(false)
		call_deferred("_refresh_editor_preview")
		return
	super._ready()
	_configure_nav_agent()


## Tunables come from config so designers tweak follow feel in one place (AGENTS.md).
func _configure_nav_agent() -> void:
	if _nav_agent == null:
		return
	_nav_agent.radius = Config.NAV_AGENT_RADIUS
	_nav_agent.height = Config.NAV_AGENT_HEIGHT
	_nav_agent.path_desired_distance = Config.COMPANION_NAV_PATH_DESIRED_DISTANCE
	_nav_agent.target_desired_distance = Config.COMPANION_NAV_TARGET_DESIRED_DISTANCE


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_refresh_editor_preview")


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree() and not _editor_snapping:
		_align_visual_to_feet()
		call_deferred("_snap_editor_to_floor")


func _refresh_editor_preview() -> void:
	if not is_inside_tree():
		return
	_model_fitted = false
	_fit_model_to_feet()
	_align_visual_to_feet()
	call_deferred("_snap_editor_to_floor")


func _align_visual_to_feet() -> void:
	if _visual == null:
		return
	# 3D playground: feet on the capsule; GPU depth buffer handles draw order (PROJECT.md §4).
	_visual.position.y = 0.0


## Drop the body onto world collision so designers only place X/Z in the area scene.
func _snap_editor_to_floor() -> void:
	if _editor_snapping or not Engine.is_editor_hint() or not is_inside_tree():
		return
	_editor_snapping = true
	var space := get_world_3d().direct_space_state
	if space != null:
		var from := global_position + Vector3(0.0, Config.EDITOR_FLOOR_SNAP_RAY_ABOVE, 0.0)
		var to := global_position - Vector3(0.0, Config.EDITOR_FLOOR_SNAP_RAY_BELOW, 0.0)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = Config.COLLISION_LAYER_WORLD
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			global_position.y = hit.position.y
			_editor_snapping = false
			return
	snap_to_floor()
	_editor_snapping = false


## Place feet at spawn_feet; spawn_height should be above local floor so snap_to_floor can find it.
func setup(slot: int, spawn_feet: Vector2, spawn_height: float = 0.0) -> void:
	_slot = slot
	process_priority = 1 + slot
	global_position = Vector3(spawn_feet.x, spawn_height, spawn_feet.y)
	_last_feet = spawn_feet
	_data = CompanionData.new()
	_data.configure_slot(slot)
	_data.last_progress_pos = spawn_feet
	_init_formation()
	_model_fitted = false
	_fit_model_to_feet()
	_align_visual_to_feet()
	call_deferred("snap_to_floor")


## Keep editor-placed transform — used when the companion lives in the area scene.
func activate(slot: int) -> void:
	_slot = slot
	process_priority = 1 + slot
	_last_feet = Vector2(global_position.x, global_position.z)
	_data = CompanionData.new()
	_data.configure_slot(slot)
	_data.last_progress_pos = _last_feet
	_init_formation()
	_model_fitted = false
	_fit_model_to_feet()
	_align_visual_to_feet()
	call_deferred("snap_to_floor")


## Fan companions out behind the player: a deterministic per-slot angle (0, +A, -A, +2A, ...)
## plus a small random jitter so multiple cats never target the exact same point.
func _init_formation() -> void:
	var pair := int((_slot + 1) / 2)
	var side := 1.0 if _slot % 2 == 1 else -1.0
	var base_angle := float(pair) * Config.COMPANION_FORMATION_ANGLE * side
	_formation_angle = base_angle + randf_range(
		-Config.COMPANION_FORMATION_JITTER_ANGLE, Config.COMPANION_FORMATION_JITTER_ANGLE)
	_formation_distance_jitter = randf_range(
		-Config.COMPANION_FORMATION_JITTER_DISTANCE, Config.COMPANION_FORMATION_JITTER_DISTANCE)
	_back_dir = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		velocity = Vector3.ZERO
		_update_walk_anim(false, 0.0)
		return

	var player: CharacterBody3D = GameState.player
	if player == null:
		velocity = Vector3.ZERO
		_update_walk_anim(false, 0.0)
		return

	# Prefer navmesh follow where a region exists; fall back to grid follow (e.g. village_green).
	if _navigation_active():
		_nav_follow(delta, player)
	else:
		_grid_follow(delta, player)


## True when the agent's navigation map has synchronised and holds at least one baked region.
func _navigation_active() -> bool:
	if _nav_agent == null:
		return false
	var map: RID = _nav_agent.get_navigation_map()
	if not map.is_valid():
		return false
	# iteration_id is 0 until the map's first synchronisation; querying before then errors.
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	return NavigationServer3D.map_get_regions(map).size() > 0


## NavigationAgent3D follow: aim for this companion's formation point behind the player, steer along
## the path with speed that ramps up with distance, and stop once the spot is reached. When the
## brain is enabled and the player is settled nearby, the goal comes from the brain (roam/circle/rest).
func _nav_follow(delta: float, player: CharacterBody3D) -> void:
	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	var comp_feet := Vector2(global_position.x, global_position.z)
	var player_velocity := _read_player_velocity(player)
	_update_back_dir(player_velocity, comp_feet, player_feet)

	var formation_target := player_feet + _back_dir.rotated(_formation_angle) * (
		Config.COMPANION_STOP_DISTANCE + _formation_distance_jitter)

	# Default motor goal is the follow formation point; the brain may override it with an autonomy goal.
	var goal_feet := formation_target
	var hold := false
	var following := true
	if Config.COMPANION_BRAIN_ENABLED:
		var player_moving := player_velocity.length_squared() > 0.09
		var step := CompanionBrain.evaluate(
			comp_feet, player_feet, player_moving, formation_target, _data, delta)
		if not step.bark_text.is_empty():
			Events.companion_barked.emit(self, step.bark_text)
		goal_feet = step.target_feet
		hold = step.hold
		following = step.following

	var dist_to_player := comp_feet.distance_to(player_feet)
	var dist_to_goal := comp_feet.distance_to(goal_feet)

	_nav_goal_timer -= delta
	var arrived := hold or dist_to_goal <= Config.COMPANION_NAV_TARGET_DESIRED_DISTANCE
	if not arrived and following and dist_to_player <= Config.COMPANION_MIN_PLAYER_GAP:
		arrived = true
	if arrived:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		if _nav_goal_timer <= 0.0:
			var raw_goal := Vector3(goal_feet.x, player.global_position.y, goal_feet.y)
			# Snap the goal onto the navmesh so the companion never chases a point off an edge.
			var map: RID = _nav_agent.get_navigation_map()
			_nav_agent.target_position = NavigationServer3D.map_get_closest_point(map, raw_goal)
			_nav_goal_timer = Config.COMPANION_NAV_GOAL_INTERVAL
		if _nav_agent.is_navigation_finished():
			velocity.x = 0.0
			velocity.z = 0.0
		else:
			var to_next := _nav_agent.get_next_path_position() - global_position
			to_next.y = 0.0
			var direction := to_next.normalized() if to_next.length() > 0.001 else Vector3.ZERO
			var speed := _follow_speed(dist_to_player)
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

	var before := Vector2(global_position.x, global_position.z)
	apply_gravity(delta)
	move_and_slide()
	var move_delta := Vector2(global_position.x, global_position.z) - before
	var move_speed := move_delta.length() / delta if delta > 0.0 else 0.0
	_update_facing(move_delta)
	_update_walk_anim(move_speed > 0.05, move_speed)
	_last_feet = Vector2(global_position.x, global_position.z)


## Speed ramps from a gentle pace near the player up to catch-up speed far away.
func _follow_speed(dist_to_player: float) -> float:
	var t := clampf(
		(dist_to_player - Config.COMPANION_STOP_DISTANCE) / Config.COMPANION_CATCHUP_RANGE, 0.0, 1.0)
	return lerpf(Config.COMPANION_FOLLOW_SPEED, Config.COMPANION_CATCHUP_SPEED, t)


## "Behind the player" tracks the player's movement while walking; holds its last value while idle.
func _update_back_dir(player_velocity: Vector2, comp_feet: Vector2, player_feet: Vector2) -> void:
	if player_velocity.length_squared() > 0.09:
		_back_dir = -player_velocity.normalized()
	elif _back_dir == Vector2.ZERO:
		# First idle frame: settle on the side the companion is already on (fallback: south).
		var away := comp_feet - player_feet
		_back_dir = away.normalized() if away.length_squared() > 0.0001 else Vector2(0.0, 1.0)


## Legacy grid A* follow — retained for areas without a navmesh (PROJECT.md §4 fallback).
func _grid_follow(delta: float, player: CharacterBody3D) -> void:
	var grid: CollisionGrid = GameState.collision_grid
	var astar: AStarGrid2D = GameState.pathfinder
	if grid == null or astar == null:
		velocity = Vector3.ZERO
		_update_walk_anim(false, 0.0)
		return

	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	var player_velocity := _read_player_velocity(player)
	var feet := Vector2(global_position.x, global_position.z)
	var previous_feet := feet
	var other_feet := _other_companion_feet()
	feet = CompanionLogic.update(
		feet,
		player_feet,
		player_velocity,
		_data,
		grid,
		astar,
		_feet_collider,
		_slot,
		delta,
		other_feet,
	)
	var move_delta := feet - previous_feet
	var move_speed := move_delta.length() / delta if delta > 0.0 else 0.0
	_apply_horizontal_velocity(feet, delta)
	apply_gravity(delta)
	move_and_slide()
	_update_facing(move_delta)
	_update_walk_anim(move_speed > 0.05, move_speed)
	_last_feet = Vector2(global_position.x, global_position.z)


func _read_player_velocity(player: CharacterBody3D) -> Vector2:
	var player_velocity: Vector2 = player.feet_velocity
	if player_velocity.length_squared() < 0.01:
		player_velocity = Vector2(player.velocity.x, player.velocity.z)
	if player_velocity.length_squared() < 0.01:
		player_velocity = InputActions.move_vector * Config.PLAYER_SPEED
	return player_velocity


func _apply_horizontal_velocity(target_feet: Vector2, delta: float) -> void:
	var offset := target_feet - Vector2(global_position.x, global_position.z)
	if offset.length_squared() < 0.0001 or delta <= 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var speed := minf(offset.length() / delta, Config.COMPANION_SPEED)
	var direction := offset.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.y * speed


func get_debug_path() -> PackedVector2Array:
	if _navigation_active():
		var nav_path := PackedVector2Array()
		for point in _nav_agent.get_current_navigation_path():
			nav_path.append(Vector2(point.x, point.z))
		return nav_path
	return _data.path


func get_debug_path_index() -> int:
	return _data.path_index


func get_debug_slot() -> int:
	return _slot


## Headless tests read fitted mesh metrics through this helper.
func get_visual_debug_state() -> Dictionary:
	var mesh := _find_first_mesh(_model) if _model else null
	var state := {
		"model_fitted": _model_fitted,
		"mesh_visible": mesh.visible if mesh else false,
		"has_skin": mesh.skin != null if mesh else false,
		"has_walk_anim": _anim != null and _anim.has_animation(Config.COMPANION_WALK_ANIM),
		"model_scale": _model.scale if _model else Vector3.ZERO,
		"model_pos": _model.position if _model else Vector3.ZERO,
		"visual_pos": _visual.position if _visual else Vector3.ZERO,
		"on_floor": is_on_floor(),
	}
	if mesh != null:
		state["mesh_aabb"] = _global_mesh_aabb(mesh)
		state["mesh_local_aabb"] = mesh.get_aabb()
		var mat: Material = mesh.get_surface_override_material(0)
		if mat == null:
			mat = mesh.get_active_material(0)
		state["material"] = mat
	return state


func _other_companion_feet() -> PackedVector2Array:
	var feet := PackedVector2Array()
	for i in GameState.companions.size():
		if i == _slot:
			continue
		var other: Node3D = GameState.companions[i]
		if other == null or not is_instance_valid(other):
			continue
		feet.append(Vector2(other.global_position.x, other.global_position.z))
	return feet


func _fit_model_to_feet() -> void:
	if _model == null or _model_fitted or not is_inside_tree():
		return

	_model.scale = Vector3.ONE
	_model.position = Vector3.ZERO
	_model.rotation = Vector3.ZERO

	var mesh := _find_first_mesh(_model)
	if mesh == null:
		push_warning("Companion: no mesh in cat.glb")
		return

	var local: AABB = mesh.get_aabb()
	if local.size.y < 0.001:
		push_warning("Companion: mesh bounds are empty")
		return

	var fit_scale := Config.COMPANION_MODEL_TARGET_HEIGHT / local.size.y
	_model.scale = Vector3.ONE * fit_scale
	# Align mesh AABB bottom to the visual root, then lift slightly above the floor plane.
	_model.position.y = (
		-local.position.y * fit_scale + Config.COMPANION_MESH_FLOOR_CLEARANCE
	)
	_anim = _find_animation_player(_model)
	_tweak_mesh_material(mesh)
	_model_fitted = true


func _tweak_mesh_material(mesh: MeshInstance3D) -> void:
	var mat: Material = mesh.get_active_material(0)
	if mat == null:
		return
	var std := mat.duplicate() as StandardMaterial3D
	std.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	std.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_surface_override_material(0, std)


func _global_mesh_aabb(mesh: MeshInstance3D) -> AABB:
	var box := AABB()
	var first := true
	var gt := mesh.global_transform
	var local: AABB = mesh.get_aabb()
	for i in 8:
		var corner: Vector3 = gt * local.get_endpoint(i)
		if first:
			box = AABB(corner, Vector3.ZERO)
			first = false
		else:
			box = box.expand(corner)
	return box


func _find_first_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_first_mesh(child)
		if found != null:
			return found
	return null


func _update_facing(move_delta: Vector2) -> void:
	if move_delta.length_squared() < 0.0001:
		return
	# Free rotation in XZ feet space — +Y is world south (+Z).
	_visual.rotation.y = (
		atan2(move_delta.x, move_delta.y) + Config.COMPANION_MODEL_YAW_OFFSET
	)


func _update_walk_anim(moving: bool, move_speed: float) -> void:
	if _anim == null:
		return
	if not moving:
		if _anim.is_playing():
			_anim.pause()
		return
	if _anim.current_animation != Config.COMPANION_WALK_ANIM:
		_anim.play(Config.COMPANION_WALK_ANIM)
	var pace := clampf(move_speed / Config.COMPANION_SPEED, 0.15, 1.5)
	_anim.speed_scale = pace * Config.COMPANION_WALK_ANIM_SPEED


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
