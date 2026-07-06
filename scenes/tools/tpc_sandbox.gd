extends Node
## Isolated sandbox for Jeheno third-person controller — Esc / Start returns to main game.

const TpcInputSetupScript := preload("res://scenes/tools/tpc_input_setup.gd")
const GamepadInputScript := preload("res://input/gamepad.gd")
const TEST_MAP_PATH := "res://addons/JehenoThirdPersonController/Map/test_map_scene.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"

const LOOK_SENSITIVITY := 9.0
const LOOK_DEADZONE := 0.18

var _cam_holder: Node3D = null


func _ready() -> void:
	TpcInputSetupScript.ensure_actions_registered()
	var test_map: PackedScene = load(TEST_MAP_PATH)
	if test_map == null:
		push_error("TPC sandbox: failed to load test map")
		return
	add_child(test_map.instantiate())
	call_deferred("_bind_camera")


func _exit_tree() -> void:
	_release_mouse()


func _process(delta: float) -> void:
	_apply_gamepad_look(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _is_exit_requested(event):
		_return_to_main()


func _is_exit_requested(event: InputEvent) -> bool:
	if not event.is_pressed():
		return false
	if event.is_action("pause"):
		return true
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).button_index == JOY_BUTTON_START
	return false


func _return_to_main() -> void:
	_release_mouse()
	var viewport := get_viewport()
	if viewport:
		viewport.set_input_as_handled()
	get_tree().change_scene_to_file(MAIN_SCENE)


func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _bind_camera() -> void:
	_cam_holder = _find_camera_holder(self)


func _apply_gamepad_look(delta: float) -> void:
	if _cam_holder == null or not _cam_holder.has_method("rotate_from_vector"):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var device := GamepadInputScript.active_device()
	if device < 0:
		return

	var look := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y),
	)
	if look.length() <= LOOK_DEADZONE:
		return

	var scale := LOOK_SENSITIVITY * delta
	if _cam_holder.has_method("get") and _cam_holder.get("mouse_sensibility") != null:
		scale *= float(_cam_holder.get("mouse_sensibility")) * 100.0
	_cam_holder.rotate_from_vector(look * scale)


func _find_camera_holder(root: Node) -> Node3D:
	for node in root.find_children("*", "Node3D", true, false):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with(
			"camera_holder_script.gd"
		):
			return node as Node3D
	return null
