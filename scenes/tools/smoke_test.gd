extends SceneTree
## Headless smoke test — run with: bash scripts/run_smoke_test.sh

const AREA_ID := "playground"
const SPAWN_FEET := Vector2(49.783, 39.947)
const SOLID_MARKER_CELL := Vector2i(60, 40)

const FEET_COLLIDER := Rect2(-0.25, -0.25, 0.5, 0.5)
const COMPANION_COLLIDER := Rect2(-0.2, -0.2, 0.4, 0.4)
const MovementLogic := preload("res://core/movement/movement.gd")
const GridPathfindingLogic := preload("res://core/pathfinding/pathfinding.gd")
const CompanionLogicScript := preload("res://core/companion/companion_logic.gd")
const CompanionDataScript := preload("res://core/companion/companion_data.gd")
const DialogueDataScript := preload("res://core/dialogue/dialogue_data.gd")
const InteractionLogicScript := preload("res://core/interaction/interaction.gd")


func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return

	var main: Node = main_scene.instantiate()
	root.add_child(main)

	await process_frame

	var game_state: Node = root.get_node("GameState")
	var player: CharacterBody3D = game_state.player
	if player == null:
		push_error("GameState.player is null after main _ready")
		quit(1)
		return

	if game_state.current_area_id != AREA_ID:
		push_error("Expected %s, got: %s" % [AREA_ID, game_state.current_area_id])
		quit(1)
		return

	var grid = game_state.collision_grid
	if grid == null:
		push_error("GameState.collision_grid is null")
		quit(1)
		return

	if game_state.pathfinder == null:
		push_error("GameState.pathfinder is null")
		quit(1)
		return

	if game_state.companion == null:
		push_error("GameState.companion is null")
		quit(1)
		return

	_test_movement_open(grid)
	_test_movement_blocked(grid)
	_test_marker_cell_solid(grid)
	_test_companion_path(game_state.pathfinder, grid)
	await _test_companion_follow(game_state.pathfinder, grid)
	_test_dialogue_data()
	_test_bat_npc(game_state)
	_test_npc_floor_height(game_state)
	_test_interaction_ray_at_npc(game_state)
	_test_interaction_ray_at_bat(game_state)
	await _test_interaction_dialogue_at_gdbot(game_state)
	_test_companion_visual(game_state)

	print(
		"SMOKE_OK: player at ",
		player.global_position,
		" companion at ",
		game_state.companion.global_position,
		" area=",
		game_state.current_area_id,
	)
	quit(0)


func _test_movement_open(grid) -> void:
	var start := SPAWN_FEET
	var moved := MovementLogic.apply_velocity(
		grid,
		start,
		Vector2(1.0, 0.0),
		FEET_COLLIDER,
		0.5,
	)
	if moved.distance_to(start) < 0.01:
		push_error("Expected open movement east from spawn, got no displacement")
		quit(1)


func _test_movement_blocked(grid) -> void:
	var start := Vector2(110.0, SPAWN_FEET.y)
	var moved := MovementLogic.apply_velocity(
		grid,
		start,
		Vector2(10.0, 0.0),
		FEET_COLLIDER,
		1.0,
	)
	if moved.x > start.x + 0.05:
		push_error("Expected east movement to be blocked near map edge")
		quit(1)


func _test_marker_cell_solid(grid) -> void:
	if not grid.is_cell_solid(SOLID_MARKER_CELL.x, SOLID_MARKER_CELL.y):
		push_error("Expected marker cell %s to be solid" % SOLID_MARKER_CELL)
		quit(1)


func _test_companion_path(astar, grid) -> void:
	var path := GridPathfindingLogic.find_path(
		astar,
		grid,
		SPAWN_FEET + Vector2(-2.0, 0.0),
		SPAWN_FEET,
	)
	if path.is_empty():
		push_error("Expected A* path toward spawn feet")
		quit(1)


func _test_companion_follow(astar, grid) -> void:
	var data = CompanionDataScript.new()
	var comp_feet := SPAWN_FEET + Vector2(-2.0, 0.0)
	var player_feet := SPAWN_FEET

	for _i in 30:
		comp_feet = CompanionLogicScript.update(
			comp_feet,
			player_feet,
			Vector2.ZERO,
			data,
			grid,
			astar,
			COMPANION_COLLIDER,
			0,
			0.1,
		)
		await process_frame

	if comp_feet.distance_to(SPAWN_FEET + Vector2(-2.0, 0.0)) < 0.05:
		push_error("Expected companion to move toward player")
		quit(1)

	var follow_dist: float = CompanionLogicScript.follow_distance(0)
	if comp_feet.distance_to(player_feet) > follow_dist + 0.5:
		push_error("Expected companion to finish within follow distance of player")
		quit(1)

	_test_companion_follow_while_player_moves(grid, astar)


func _test_companion_follow_while_player_moves(grid, astar) -> void:
	var data = CompanionDataScript.new()
	var comp_feet := SPAWN_FEET + Vector2(-2.0, 0.0)
	var player_feet := SPAWN_FEET
	var player_velocity := Vector2(1.0, 0.0) * 4.5
	var start_comp := comp_feet

	for _i in 20:
		player_feet += player_velocity * 0.1
		comp_feet = CompanionLogicScript.update(
			comp_feet,
			player_feet,
			player_velocity,
			data,
			grid,
			astar,
			COMPANION_COLLIDER,
			0,
			0.1,
		)

	if comp_feet.distance_to(start_comp) < 0.05:
		push_error("Expected companion to move while player is walking")
		quit(1)

	_test_companion_moves_when_ahead_of_player(grid, astar)


func _test_companion_separation(grid) -> void:
	var collider := COMPANION_COLLIDER
	var stacked := SPAWN_FEET
	var other := SPAWN_FEET + Vector2(0.05, 0.0)
	var others := PackedVector2Array([other])

	if not CompanionLogicScript.blocked_by_companions(stacked, collider, others):
		push_error("Expected overlapping companion feet to register as blocked")
		quit(1)

	var separated := CompanionLogicScript.nudge_from_companions(
		stacked, collider, 0, others, grid,
	)
	if CompanionLogicScript.feet_overlap(separated, collider, other, collider):
		push_error("Expected nudge to separate stacked companions")
		quit(1)


func _test_companion_moves_when_ahead_of_player(grid, astar) -> void:
	var data = CompanionDataScript.new()
	var comp_feet := SPAWN_FEET + Vector2(1.0, 0.0)
	var player_feet := SPAWN_FEET
	var player_velocity := Vector2(1.0, 0.0) * 4.5
	var start_comp := comp_feet

	for _i in 15:
		player_feet += player_velocity * 0.1
		var before := comp_feet
		comp_feet = CompanionLogicScript.update(
			comp_feet,
			player_feet,
			player_velocity,
			data,
			grid,
			astar,
			COMPANION_COLLIDER,
			0,
			0.1,
		)
		if comp_feet.distance_to(before) > 0.001:
			return

	_test_companion_separation(grid)
	push_error("Expected companion to move every frame while player walks, even when starting ahead")
	quit(1)


func _test_dialogue_data() -> void:
	if DialogueDataScript.line_count(0) != 1:
		push_error("Expected Bat dialogue to have 1 line")
		quit(1)
	if DialogueDataScript.get_line(0, 0) != "Hello.":
		push_error("Expected Bat first line to be Hello.")
		quit(1)


func _find_npc_by_id(game_state: Node, npc_id: String) -> Node3D:
	for npc in game_state.npcs:
		if npc != null and npc.get("npc_id") == npc_id:
			return npc as Node3D
	return null


func _aim_camera_at(player: CharacterBody3D, aim_target: Vector3) -> void:
	var cam_holder: Node3D = player.get("cam_holder") as Node3D
	if cam_holder == null:
		return
	var flat_target := Vector3(aim_target.x, cam_holder.global_position.y, aim_target.z)
	cam_holder.look_at(flat_target, Vector3.UP)
	var flat_player := Vector3(aim_target.x, player.global_position.y, aim_target.z)
	player.look_at(flat_player, Vector3.UP)


func _test_bat_npc(game_state: Node) -> void:
	if game_state.npcs.is_empty():
		push_error("Expected at least one NPC in playground")
		quit(1)

	var bat := _find_npc_by_id(game_state, "bat")
	if bat == null:
		push_error("Expected Bat NPC in playground")
		quit(1)

	var player: CharacterBody3D = game_state.player
	var player_at_npc := Vector2(bat.global_position.x, bat.global_position.z)
	player.global_position = Vector3(player_at_npc.x, bat.global_position.y, player_at_npc.y)

	var in_range := InteractionLogicScript.find_nearest_npc(player_at_npc, game_state.npcs)
	if in_range != bat:
		push_error("Expected Bat as nearest NPC when standing on same tile")
		quit(1)

	var active := InteractionLogicScript.find_npc_from_ray(bat, game_state.npcs)
	if active != bat:
		push_error("Expected Bat as ray interact target when collider is Bat body")
		quit(1)

	if not bat.has_node("Interactable"):
		push_error("Expected Bat NPC to have Interactable child (reference pattern)")
		quit(1)


func _test_interaction_ray_at_npc(game_state: Node) -> void:
	var player: CharacterBody3D = game_state.player
	if player == null or not player.has_method("handle_interaction"):
		push_error("Expected WhiskerboundPlayer for interaction ray test")
		quit(1)

	var ray: RayCast3D = player.get_node_or_null("%InteractionRaycast") as RayCast3D
	if ray == null:
		push_error("Expected %InteractionRaycast on player")
		quit(1)

	var gdbot := _find_npc_by_id(game_state, "gdbot")
	if gdbot == null:
		push_error("Expected GDBot NPC for interaction ray test")
		quit(1)

	var aim_target := gdbot.global_position + Vector3(0.0, 1.2, 0.0)
	player.global_position = gdbot.global_position + Vector3(0.0, 0.0, 2.0)
	player.global_position.y = gdbot.global_position.y
	_aim_camera_at(player, aim_target)

	await physics_frame
	await physics_frame
	player.call("handle_interaction")

	if str(game_state.interact_target_name).is_empty():
		push_error("Expected interact target when ray aimed at GDBot, got none")
		quit(1)


func _test_npc_floor_height(game_state: Node) -> void:
	for npc in game_state.npcs:
		if npc == null or not (npc is Node3D):
			continue
		var npc_y: float = (npc as Node3D).global_position.y
		if npc_y < 3.5:
			push_error("Expected NPC %s above floor, got y=%.2f" % [(npc as Node).name, npc_y])
			quit(1)


func _test_interaction_ray_at_bat(game_state: Node) -> void:
	var player: CharacterBody3D = game_state.player
	if player == null or not player.has_method("handle_interaction"):
		push_error("Expected WhiskerboundPlayer for Bat ray test")
		quit(1)

	var bat: CharacterBody3D = _find_npc_by_id(game_state, "bat") as CharacterBody3D
	if bat == null:
		push_error("Expected Bat NPC for interaction ray test")
		quit(1)

	const CHARACTER_LAYER := 1
	if bat.collision_layer != CHARACTER_LAYER:
		push_error(
			"Expected Bat on character layer %d, got layer %d"
			% [CHARACTER_LAYER, bat.collision_layer]
		)
		quit(1)

	var aim_target := bat.global_position + Vector3(0.0, 0.2, 0.0)
	player.global_position = bat.global_position + Vector3(0.0, 0.0, 2.5)
	player.global_position.y = bat.global_position.y
	_aim_camera_at(player, aim_target)

	await physics_frame
	await physics_frame
	player.call("handle_interaction")

	if str(game_state.interact_target_name).is_empty():
		push_error("Expected interact target when ray aimed at Bat, got none")
		quit(1)

	var ray: RayCast3D = player.get_node_or_null("%InteractionRaycast") as RayCast3D
	ray.force_raycast_update()
	if not ray.is_colliding():
		push_error("Expected Bat ray hit when aimed at Bat")
		quit(1)
	var collider: Object = ray.get_collider()
	if collider is CollisionObject3D:
		var hit_layer: int = (collider as CollisionObject3D).collision_layer
		if hit_layer != CHARACTER_LAYER:
			push_error("Expected Bat ray hit on layer %d, got %d" % [CHARACTER_LAYER, hit_layer])
			quit(1)


func _test_interaction_dialogue_at_gdbot(game_state: Node) -> void:
	var gdbot := _find_npc_by_id(game_state, "gdbot")
	if gdbot == null:
		push_error("Expected GDBot NPC for dialogue interact test")
		quit(1)

	var interactable: Node = gdbot.get_node_or_null("Interactable")
	if interactable == null:
		push_error("Expected GDBot Interactable child for dialogue test")
		quit(1)

	interactable.call("interact", game_state.player)
	await process_frame

	if game_state.mode != game_state.GameMode.DIALOGUE:
		push_error("Expected DIALOGUE after interact at GDBot")
		quit(1)
	if game_state.dialogue_id != DialogueDataScript.dialogue_id_for_npc("gdbot"):
		push_error("Expected GDBot dialogue id after interact")
		quit(1)

	game_state.mode = game_state.GameMode.GAMEPLAY
	game_state.dialogue_id = -1


func _test_companion_visual(game_state: Node) -> void:
	var companion: Node = game_state.companion
	if companion == null or not companion.has_method("get_visual_debug_state"):
		push_error("Companion visual debug API missing")
		quit(1)

	var state: Dictionary = companion.get_visual_debug_state()
	if not state.get("model_fitted", false):
		push_error("Companion model was not fitted")
		quit(1)
	if not state.get("mesh_visible", false):
		push_error("Companion mesh is not visible")
		quit(1)
	if not state.get("has_skin", false):
		push_error("Companion mesh has no skin")
		quit(1)
	if not state.get("has_walk_anim", false):
		push_error("Companion missing walk animation")
		quit(1)

	var model_scale: Vector3 = state.get("model_scale", Vector3.ZERO)
	if model_scale.x < 0.001:
		push_error("Companion model scale too small: %s" % model_scale)
		quit(1)

	var bind: AABB = state.get("mesh_aabb", AABB())
	if bind.size.y < 0.25 or bind.size.y > 0.55:
		push_error("Companion mesh height out of range: %s" % bind.size)
		quit(1)
	if bind.position.y < -0.05:
		push_error("Companion mesh below ground: %s" % bind)
		quit(1)

	var mat: Material = state.get("material")
	if mat is StandardMaterial3D:
		var std := mat as StandardMaterial3D
		if std.albedo_texture == null:
			push_error("Companion material missing albedo texture")
			quit(1)
	else:
		push_error("Companion mesh missing StandardMaterial3D override")
		quit(1)

