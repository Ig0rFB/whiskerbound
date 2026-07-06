extends RefCounted
## Registers Jeheno TPC input actions before the sandbox loads — avoids runtime warnings.

const DEFAULT_BINDINGS := {
	"play_char_move_forward_action": [
		{"type": "key", "code": KEY_W},
		{"type": "key", "code": KEY_UP},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_UP},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0},
	],
	"play_char_move_backward_action": [
		{"type": "key", "code": KEY_S},
		{"type": "key", "code": KEY_DOWN},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_DOWN},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0},
	],
	"play_char_move_left_action": [
		{"type": "key", "code": KEY_A},
		{"type": "key", "code": KEY_LEFT},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_LEFT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0},
	],
	"play_char_move_right_action": [
		{"type": "key", "code": KEY_D},
		{"type": "key", "code": KEY_RIGHT},
		{"type": "joy_button", "code": JOY_BUTTON_DPAD_RIGHT},
		{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0},
	],
	"play_char_run_action": [
		{"type": "key", "code": KEY_SHIFT},
		{"type": "joy_button", "code": JOY_BUTTON_Y},
	],
	"play_char_jump_action": [
		{"type": "key", "code": KEY_SPACE},
		{"type": "joy_button", "code": JOY_BUTTON_A},
		{"type": "joy_button", "code": JOY_BUTTON_B},
	],
	"play_char_mouse_mode_action": [
		{"type": "key", "code": KEY_CTRL},
		{"type": "joy_button", "code": JOY_BUTTON_LEFT_STICK},
	],
	"play_char_aim_cam_action": [
		{"type": "mouse", "code": MOUSE_BUTTON_RIGHT},
		{"type": "joy_button", "code": JOY_BUTTON_RIGHT_SHOULDER},
	],
	"play_char_aim_cam_side_action": [{"type": "key", "code": KEY_G}],
	"play_char_cam_zoom_in_action": [
		{"type": "mouse", "code": MOUSE_BUTTON_WHEEL_UP},
		{"type": "key", "code": KEY_V},
		{"type": "joy_axis", "axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0},
	],
	"play_char_cam_zoom_out_action": [
		{"type": "mouse", "code": MOUSE_BUTTON_WHEEL_DOWN},
		{"type": "key", "code": KEY_B},
		{"type": "joy_axis", "axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0},
	],
	"play_char_change_cam_collision_action": [{"type": "key", "code": KEY_T}],
}


static func ensure_actions_registered() -> void:
	for action_name in DEFAULT_BINDINGS:
		var action := StringName(action_name)
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		# Replace bindings so stale defaults (e.g. X for run) do not linger.
		for existing in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, existing)
		for binding in DEFAULT_BINDINGS[action_name]:
			var event := _make_input_event(binding)
			if event != null:
				InputMap.action_add_event(action, event)


static func _make_input_event(binding: Dictionary) -> InputEvent:
	match binding["type"]:
		"key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = binding["code"]
			return key_event
		"mouse":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = binding["code"]
			return mouse_event
		"joy_button":
			var button_event := InputEventJoypadButton.new()
			button_event.button_index = binding["code"]
			return button_event
		"joy_axis":
			var axis_event := InputEventJoypadMotion.new()
			axis_event.axis = binding["axis"]
			axis_event.axis_value = binding["value"]
			return axis_event
	return null
