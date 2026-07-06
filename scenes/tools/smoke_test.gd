extends SceneTree
## Headless smoke test — run with: bash scripts/run_smoke_test.sh

const AREA_ID := "playground"
const SPAWN_FEET := Vector2(51.0, 38.0)
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
	_test_elder_cat_npc(game_state)
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
	if DialogueDataScript.line_count(0) != 3:
		push_error("Expected Elder Cat dialogue to have 3 lines")
		quit(1)
	if DialogueDataScript.get_line(0, 0).is_empty():
		push_error("Expected non-empty first Elder Cat line")
		quit(1)


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


func _test_elder_cat_npc(game_state: Node) -> void:
	if game_state.npcs.is_empty():
		push_error("Expected at least one NPC in playground")
		quit(1)

	var player: CharacterBody3D = game_state.player
	var elder = game_state.npcs[0]
	var player_at_npc := Vector2(elder.global_position.x, elder.global_position.z)
	player.global_position = Vector3(player_at_npc.x, elder.global_position.y, player_at_npc.y)

	if InteractionLogicScript.find_nearest_npc(player_at_npc, game_state.npcs) == null:
		push_error("Expected Elder Cat in interact range when player stands on same tile")
		quit(1)
