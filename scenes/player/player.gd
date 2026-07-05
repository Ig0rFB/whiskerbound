extends CharacterBody3D
## Player avatar — 8-direction grid movement with wall sliding (PROJECT.md §9.1).

@onready var _visual: MeshInstance3D = $Visual

var _facing: GameTypes.Direction8 = GameTypes.Direction8.SOUTH
var _feet_collider: Rect2 = PlayerCollider.feet_rect()


func _physics_process(delta: float) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		return

	var grid: CollisionGrid = GameState.collision_grid
	if grid == null:
		return

	var velocity := InputActions.move_vector * Config.PLAYER_SPEED
	var feet := Vector2(global_position.x, global_position.z)
	feet = Movement.apply_velocity(grid, feet, velocity, _feet_collider, delta)
	global_position = Vector3(feet.x, 0.0, feet.y)

	if InputActions.move_vector.length_squared() > 0.0001:
		_facing = GameTypes.facing_from_vector(InputActions.move_vector, _facing)
		_visual.rotation.y = GameTypes.yaw_from_facing(_facing)

	DepthSort.apply_to_mesh(_visual, 0.35, global_position.z)


func face_toward_world(target_feet: Vector2) -> void:
	var feet := Vector2(global_position.x, global_position.z)
	var direction := target_feet - feet
	_facing = GameTypes.facing_from_vector(direction, _facing)
	_visual.rotation.y = GameTypes.yaw_from_facing(_facing)
