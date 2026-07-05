extends Node
## Maps InputMap actions to gameplay vectors (PROJECT.md §11).

var move_vector: Vector2 = Vector2.ZERO
var toggle_collision_debug_pressed: bool = false
var interact_pressed: bool = false


func poll() -> void:
	move_vector = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		move_vector.x += 1.0
	if Input.is_action_pressed("move_left"):
		move_vector.x -= 1.0
	if Input.is_action_pressed("move_down"):
		move_vector.y += 1.0
	if Input.is_action_pressed("move_up"):
		move_vector.y -= 1.0
	move_vector = Movement.normalise_input(move_vector)

	toggle_collision_debug_pressed = Input.is_action_just_pressed("toggle_collision_debug")
	interact_pressed = Input.is_action_just_pressed("interact")
