extends "res://addons/JehenoThirdPersonController/PlayerCharacter/StateMachine/player_character_script.gd"
## Whiskerbound player — Jeheno third-person controller with companion + UI hooks.

const GamepadInputScript := preload("res://input/gamepad.gd")

const LOOK_SENSITIVITY := 9.0
const LOOK_DEADZONE := 0.18

var feet_velocity: Vector2 = Vector2.ZERO

var _last_feet: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	_disable_embedded_hud()
	call_deferred("_bind_camera_to_game_state")
	call_deferred("capture_camera_mouse")


func _disable_embedded_hud() -> void:
	var embedded_hud := get_node_or_null("HUD")
	if embedded_hud == null:
		return
	embedded_hud.visible = false
	embedded_hud.process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	super._process(delta)
	if GameState.mode == GameState.GameMode.GAMEPLAY:
		_apply_gamepad_look(delta)


func _physics_process(delta: float) -> void:
	_update_feet_velocity(delta)
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		velocity.x = 0.0
		velocity.z = 0.0
		if is_on_floor():
			velocity.y = 0.0
		else:
			gravity_apply(delta)
		move_and_slide()
		return
	super._physics_process(delta)


func face_toward_world(target_feet: Vector2) -> void:
	var feet := Vector2(global_position.x, global_position.z)
	var direction := target_feet - feet
	if direction.length_squared() < 0.0001:
		return
	var target_angle := -direction.orthogonal().angle()
	visual_root.rotation.y = target_angle


func set_camera_input_enabled(enabled: bool) -> void:
	if cam_holder != null:
		cam_holder.set_active(enabled)


func capture_camera_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_camera_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func get_camera_distance() -> float:
	if cam_holder == null:
		return 0.0
	var spring: SpringArm3D = cam_holder.get_node_or_null("%SpringArm3D") as SpringArm3D
	if spring == null:
		return 0.0
	return spring.spring_length


func get_camera_pitch_degrees() -> float:
	if cam_holder == null:
		return 0.0
	return rad_to_deg(cam_holder.rotation.x)


func set_camera_distance(dist: float) -> void:
	if cam_holder == null:
		return
	var spring: SpringArm3D = cam_holder.get_node_or_null("%SpringArm3D") as SpringArm3D
	if spring == null:
		return
	spring.spring_length = clampf(
		dist,
		cam_holder.min_spring_length,
		cam_holder.max_spring_length,
	)


func _bind_camera_to_game_state() -> void:
	if cam_holder != null:
		GameState.camera_rig = cam_holder


func _update_feet_velocity(delta: float) -> void:
	var feet := Vector2(global_position.x, global_position.z)
	if delta > 0.0:
		feet_velocity = (feet - _last_feet) / delta
	else:
		feet_velocity = Vector2.ZERO
	_last_feet = feet


func _apply_gamepad_look(delta: float) -> void:
	if cam_holder == null or not cam_holder.has_method("rotate_from_vector"):
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

	var scale := LOOK_SENSITIVITY * delta * cam_holder.mouse_sensibility * 100.0
	cam_holder.rotate_from_vector(look * scale)
