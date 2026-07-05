extends CharacterBody3D
## Player avatar — 8-direction grid movement with wall sliding (PROJECT.md §9.1).

@onready var _visual: MeshInstance3D = $Visual

var _facing: GameTypes.Direction8 = GameTypes.Direction8.SOUTH
var _feet_collider: Rect2 = PlayerCollider.feet_rect()
var _last_feet: Vector2 = Vector2.ZERO
var feet_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	_last_feet = Vector2(global_position.x, global_position.z)


func _physics_process(delta: float) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		feet_velocity = Vector2.ZERO
		return

	var grid: CollisionGrid = GameState.collision_grid
	if grid == null:
		feet_velocity = Vector2.ZERO
		return

	var velocity := InputActions.move_vector * Config.PLAYER_SPEED
	var feet := Vector2(global_position.x, global_position.z)
	var previous_feet := feet
	feet = Movement.apply_velocity(grid, feet, velocity, _feet_collider, delta)
	if delta > 0.0:
		feet_velocity = (feet - previous_feet) / delta
	else:
		feet_velocity = Vector2.ZERO
	global_position = Vector3(feet.x, 0.0, feet.y)
	_last_feet = feet

	if InputActions.move_vector.length_squared() > 0.0001:
		_facing = GameTypes.facing_from_vector(InputActions.move_vector, _facing)
		_visual.rotation.y = GameTypes.yaw_from_facing(_facing)

	DepthSort.apply_to_mesh(_visual, 0.35, global_position.z)


func face_toward_world(target_feet: Vector2) -> void:
	var feet := Vector2(global_position.x, global_position.z)
	var direction := target_feet - feet
	_facing = GameTypes.facing_from_vector(direction, _facing)
	_visual.rotation.y = GameTypes.yaw_from_facing(_facing)
