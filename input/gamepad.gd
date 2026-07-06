class_name GamepadInput
extends RefCounted
## Gamepad polling — mirrors 2D prototype input/gamepad.odin (SN30 Pro / generic pads).
## Confirm/cancel use physical face positions: Switch Pro on macOS swaps Godot's A/B labels.

const DEVICE := 0

# Standard SDL trigger axes — do not include stick axes (2/3) as fallbacks.
const _LEFT_TRIGGER_AXES: Array[int] = [JOY_AXIS_TRIGGER_LEFT]
const _RIGHT_TRIGGER_AXES: Array[int] = [JOY_AXIS_TRIGGER_RIGHT]

var _was_connected := false
var _prev_held: Dictionary = {}
var _confirm_button: JoyButton = JOY_BUTTON_A
var _cancel_button: JoyButton = JOY_BUTTON_B
var _star_button: JoyButton = Config.GAMEPAD_STAR_BUTTON


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
		_apply_button_layout(name)
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


## Physical A (east on Switch) — interact, menu confirm.
func confirm_pressed() -> bool:
	return button_pressed(_confirm_button)


## Physical B (south on Switch) — back / menu cancel.
func cancel_pressed() -> bool:
	return button_pressed(_cancel_button)


## Star / capture (8BitDo bottom-left) — debug HUD toggle on Switch mode.
func star_pressed() -> bool:
	return button_pressed(_star_button)


## L2 = zoom out (+), R2 = zoom in (−). Triggers are normalised to 0..1.
func zoom_axis() -> float:
	var device := active_device()
	if device < 0:
		return 0.0
	var l2 := _read_trigger(device, _trigger_axes_for(device, true))
	var r2 := _read_trigger(device, _trigger_axes_for(device, false))
	if l2 <= _deadzone() and r2 <= _deadzone():
		return 0.0
	return l2 - r2


func end_frame() -> void:
	var device := active_device()
	if device < 0:
		_prev_held.clear()
		return
	for button in [
		_confirm_button,
		_cancel_button,
		_star_button,
		JOY_BUTTON_X,
		JOY_BUTTON_Y,
		JOY_BUTTON_START,
		JOY_BUTTON_BACK,
	]:
		var key := _button_key(device, button)
		_prev_held[key] = Input.is_joy_button_pressed(device, button)


func _apply_button_layout(joy_name: String) -> void:
	var lower := joy_name.to_lower()
	# Switch Pro / SN30 Pro (Switch mode): Godot A/B are Xbox-labelled; physical A is east.
	if "switch" in lower or "nintendo" in lower or "8bitdo" in lower:
		_confirm_button = JOY_BUTTON_B
		_cancel_button = JOY_BUTTON_A
	else:
		_confirm_button = JOY_BUTTON_A
		_cancel_button = JOY_BUTTON_B
	_star_button = Config.GAMEPAD_STAR_BUTTON


static func _button_key(device: int, button: JoyButton) -> String:
	return "%d:%d" % [device, int(button)]


static func _apply_stick_deadzone(vec: Vector2) -> Vector2:
	var deadzone := _deadzone()
	if vec.length() <= deadzone:
		return Vector2.ZERO
	var scaled := (vec.length() - deadzone) / (1.0 - deadzone)
	return vec.normalized() * scaled


static func _normalise_trigger(value: float) -> float:
	if value >= 0.0:
		return clampf(value, 0.0, 1.0)
	# Some pads report triggers as −1 (rest) → +1 (pressed).
	return clampf((value + 1.0) * 0.5, 0.0, 1.0)


static func _read_trigger(device: int, axes: Array[int]) -> float:
	var best := 0.0
	for axis in axes:
		best = maxf(best, _normalise_trigger(Input.get_joy_axis(device, axis)))
	return best


func _trigger_axes_for(device: int, left: bool) -> Array[int]:
	var name := Input.get_joy_name(device).to_lower()
	# 8BitDo pads in some modes map triggers to axes 6/7 instead of 4/5.
	if "8bitdo" in name:
		return [6 if left else 7, 4 if left else 5]
	return _LEFT_TRIGGER_AXES if left else _RIGHT_TRIGGER_AXES
