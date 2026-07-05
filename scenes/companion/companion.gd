extends Node3D
## Lumi — cat companion follow via A* (PROJECT.md §9.2).

@onready var _visual: MeshInstance3D = $Visual

var _data := CompanionData.new()
var _feet_collider: Rect2 = CompanionCollider.feet_rect()
var _slot: int = 0


func setup(slot: int, spawn_feet: Vector2) -> void:
	_slot = slot
	global_position = Vector3(spawn_feet.x, 0.0, spawn_feet.y)
	_data = CompanionData.new()
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
	var feet := Vector2(global_position.x, global_position.z)
	feet = CompanionLogic.update(
		feet,
		player_feet,
		_data,
		grid,
		astar,
		_feet_collider,
		_slot,
		delta,
	)
	global_position = Vector3(feet.x, 0.0, feet.y)
	DepthSort.apply_to_mesh(_visual, 0.2, global_position.z)
