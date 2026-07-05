class_name GamepadInput
extends RefCounted
## Gamepad polling — mirrors 2D prototype input/gamepad.odin (SN30 Pro / generic pads).

const DEVICE := 0

var _was_connected := false
var _prev_held: Dictionary = {}


static func _deadzone() -> float:
	return Config.GAMEPAD_DEADZONE


static func active_device() -> int:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return -1
	return int(pads[0])


func poll_connection() -> void:
	var device := active_device()
	if device < 0:
		if _was_connected:
			print("Gamepad disconnected")
			_was_connected = false
		return
	if not _was_connected:
		var name := Input.get_joy_name(device)
		if name.is_empty():
			print("Gamepad connected (device ", device, ")")
		else:
			print("Gamepad connected: ", name)
		_was_connected = true


func move_vector() -> Vector2:
	var device := active_device()
	if device < 0:
		return Vector2.ZERO

	var vec := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device, JOY_AXIS_LEFT_Y),
	)
	vec = _apply_stick_deadzone(vec)

	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT):
		vec.x = -1.0
	elif Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT):
		vec.x = 1.0
	if Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP):
		vec.y = -1.0
	elif Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN):
		vec.y = 1.0

	if vec.length_squared() > 1.0:
		return vec.normalized()
	return vec


func button_down(button: JoyButton) -> bool:
	var device := active_device()
	if device < 0:
		return false
	return Input.is_joy_button_pressed(device, button)


func button_pressed(button: JoyButton) -> bool:
	var device := active_device()
	if device < 0:
		return false
	var key := _button_key(device, button)
	var down := Input.is_joy_button_pressed(device, button)
	var was_down: bool = _prev_held.get(key, false)
	_prev_held[key] = down
	return down and not was_down


func end_frame() -> void:
	var device := active_device()
	if device < 0:
		_prev_held.clear()
		return
	for button in [
		JOY_BUTTON_A,
		JOY_BUTTON_B,
		JOY_BUTTON_X,
		JOY_BUTTON_Y,
		JOY_BUTTON_START,
		JOY_BUTTON_BACK,
	]:
		var key := _button_key(device, button)
		_prev_held[key] = Input.is_joy_button_pressed(device, button)


static func _button_key(device: int, button: JoyButton) -> String:
	return "%d:%d" % [device, int(button)]


static func _apply_stick_deadzone(vec: Vector2) -> Vector2:
	var deadzone := _deadzone()
	if vec.length() <= deadzone:
		return Vector2.ZERO
	var scaled := (vec.length() - deadzone) / (1.0 - deadzone)
	return vec.normalized() * scaled
