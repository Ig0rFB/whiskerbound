extends Node
## Maps InputMap + gamepad to gameplay vectors (PROJECT.md §11).

var move_vector: Vector2 = Vector2.ZERO
var toggle_debug_hud_pressed: bool = false
var toggle_minimap_pressed: bool = false
var pause_pressed: bool = false
var interact_pressed: bool = false
var debug_restart_pressed: bool = false
var debug_spawn_companion_pressed: bool = false
var debug_reload_area_pressed: bool = false

var _gamepad := GamepadInput.new()


func _ready() -> void:
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	poll()


func poll() -> void:
	_gamepad.poll_connection()

	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var gamepad := _gamepad.move_vector()
	var raw := keyboard
	if gamepad.length_squared() > keyboard.length_squared():
		raw = gamepad
	move_vector = Movement.normalise_input(raw)

	toggle_debug_hud_pressed = (
		Input.is_action_just_pressed("toggle_debug_hud")
	)
	toggle_minimap_pressed = (
		Input.is_action_just_pressed("toggle_minimap")
		or _gamepad.button_pressed(JOY_BUTTON_BACK)
	)
	pause_pressed = (
		Input.is_action_just_pressed("pause")
		or _gamepad.button_pressed(JOY_BUTTON_START)
	)
	interact_pressed = (
		Input.is_action_just_pressed("interact")
		or _gamepad.button_pressed(JOY_BUTTON_A)
	)
	debug_restart_pressed = Input.is_action_just_pressed("debug_restart")
	debug_spawn_companion_pressed = Input.is_action_just_pressed("debug_spawn_companion")
	debug_reload_area_pressed = Input.is_action_just_pressed("debug_reload_area")

	_gamepad.end_frame()
