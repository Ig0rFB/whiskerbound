@tool
extends GroundedCharacter
## Lumi — cat companion follow via A* (PROJECT.md §9.2).

@onready var _visual: Node3D = $Visual
@onready var _model: Node3D = $Visual/Model

var _data := CompanionData.new()
var _feet_collider: Rect2 = CompanionCollider.feet_rect()
var _slot: int = 0
var _anim: AnimationPlayer
var _last_feet: Vector2 = Vector2.ZERO
var _model_fitted := false
var _editor_snapping := false


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
	_model_fitted = false
	_fit_model_to_feet()
	_align_visual_to_feet()
	call_deferred("snap_to_floor")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		velocity = Vector3.ZERO
		_update_walk_anim(false, 0.0)
		return

	var grid: CollisionGrid = GameState.collision_grid
	var astar: AStarGrid2D = GameState.pathfinder
	var player: TpcPlayer = GameState.player
	if grid == null or astar == null or player == null:
		velocity = Vector3.ZERO
		_update_walk_anim(false, 0.0)
		return

	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	var player_velocity: Vector2 = player.feet_velocity
	if player_velocity.length_squared() < 0.01:
		player_velocity = Vector2(player.velocity.x, player.velocity.z)
	if player_velocity.length_squared() < 0.01:
		player_velocity = InputActions.move_vector * Config.PLAYER_SPEED
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
