extends Node3D
## Lumi — cat companion follow via A* (PROJECT.md §9.2).

@onready var _visual: MeshInstance3D = $Visual

var _data := CompanionData.new()
var _feet_collider: Rect2 = CompanionCollider.feet_rect()
var _slot: int = 0


func setup(slot: int, spawn_feet: Vector2) -> void:
	_slot = slot
	process_priority = 1
	global_position = Vector3(spawn_feet.x, 0.0, spawn_feet.y)
	_data = CompanionData.new()
	_data.configure_slot(slot)
	_data.last_progress_pos = spawn_feet


func _physics_process(delta: float) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		return

	var grid: CollisionGrid = GameState.collision_grid
	var astar: AStarGrid2D = GameState.pathfinder
	var player: CharacterBody3D = GameState.player
	if grid == null or astar == null or player == null:
		return

	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	var player_velocity: Vector2 = player.feet_velocity
	if player_velocity.length_squared() < 0.01:
		player_velocity = InputActions.move_vector * Config.PLAYER_SPEED
	var feet := Vector2(global_position.x, global_position.z)
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
	)
	global_position = Vector3(feet.x, 0.0, feet.y)
	DepthSort.apply_to_mesh(_visual, 0.2, global_position.z)


func get_debug_path() -> PackedVector2Array:
	return _data.path


func get_debug_path_index() -> int:
	return _data.path_index


func get_debug_slot() -> int:
	return _slot
