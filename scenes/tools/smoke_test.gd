extends SceneTree
## Headless smoke test — run with: bash scripts/run_smoke_test.sh

const FEET_COLLIDER := Rect2(-0.25, -0.25, 0.5, 0.5)
const MovementLogic := preload("res://core/movement.gd")


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

	if game_state.current_area_id != "village_green":
		push_error("Expected village_green, got: %s" % game_state.current_area_id)
		quit(1)
		return

	var grid = game_state.collision_grid
	if grid == null:
		push_error("GameState.collision_grid is null")
		quit(1)
		return

	_test_movement_open(grid)
	_test_movement_blocked(grid)
	_test_tree_cell_solid(grid)

	print(
		"SMOKE_OK: player at ",
		player.global_position,
		" area=",
		game_state.current_area_id,
	)
	quit(0)


func _test_movement_open(grid) -> void:
	var start := Vector2(10.0, 8.0)
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
	var start := Vector2(19.6, 8.0)
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


func _test_tree_cell_solid(grid) -> void:
	if not grid.is_cell_solid(4, 5):
		push_error("Expected tree cell (4, 5) to be solid")
		quit(1)
