class_name TpcPlayer
extends PlayerCharacter
## Whiskerbound player — Jeheno third-person controller with companion + UI hooks.
## Not @tool — editor preview is handled by GodotPlushSkin; @tool here spams GameState/camera errors.

const GamepadInputScript := preload("res://input/gamepad.gd")

const LOOK_SENSITIVITY := 9.0
const LOOK_DEADZONE := 0.18

var feet_velocity: Vector2 = Vector2.ZERO

var _last_feet: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	collision_mask = Config.COLLISION_LAYER_WORLD | Config.COLLISION_LAYER_CHARACTER
	_disable_embedded_hud()
	_disable_addon_camera_zoom()
	call_deferred("_bind_camera_to_game_state")
	call_deferred("capture_camera_mouse")


func _disable_embedded_hud() -> void:
	var embedded_hud := get_node_or_null("HUD")
	if embedded_hud == null:
		return
	embedded_hud.visible = false
	embedded_hud.process_mode = Node.PROCESS_MODE_DISABLED


func _disable_addon_camera_zoom() -> void:
	# Jeheno zoom misses discrete mouse-wheel ticks — handled in _process below.
	if cam_holder != null:
		cam_holder.zoom_speed = 0.0


func _process(delta: float) -> void:
	super._process(delta)
	if GameState.mode == GameState.GameMode.GAMEPLAY:
		_apply_gamepad_look(delta)
		_poll_camera_zoom(delta)


func _unhandled_input(event: InputEvent) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY or cam_holder == null:
		return
	if not event is InputEventMouseButton or not event.pressed:
		return

	var delta_dist := 0.0
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			delta_dist = -Config.CAMERA_ZOOM_WHEEL_STEP
		MOUSE_BUTTON_WHEEL_DOWN:
			delta_dist = Config.CAMERA_ZOOM_WHEEL_STEP
		_:
			return

	_apply_camera_zoom_delta(delta_dist)
	get_viewport().set_input_as_handled()


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


## Jeheno locomotion label shown on the debug HUD (`State: Idle`, `Walk`, …).
func get_locomotion_state_name() -> String:
	if state_machine == null:
		return ""
	return state_machine.curr_state_name


## True when the player is in Jeheno `IdleState` — same signal the debug HUD displays.
func is_locomotion_idle() -> bool:
	return get_locomotion_state_name() == "Idle"


## XZ velocity for companion path prediction while the player is moving.
func get_companion_follow_velocity() -> Vector2:
	if is_locomotion_idle():
		return Vector2.ZERO
	var body_vel := Vector2(velocity.x, velocity.z)
	if body_vel.length_squared() > 0.0001:
		return body_vel
	return feet_velocity


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


func _poll_camera_zoom(delta: float) -> void:
	if cam_holder == null or GameState.mode != GameState.GameMode.GAMEPLAY:
		return

	# V/B keys only — wheel is discrete via _unhandled_input; triggers via gamepad.gd.
	var axis := Input.get_axis(cam_holder.cam_zoom_in_action, cam_holder.cam_zoom_out_action)
	axis += InputActions.camera_zoom_axis
	if absf(axis) < 0.001:
		return

	_apply_camera_zoom_delta(axis * Config.CAMERA_ZOOM_SPEED * delta)


func _apply_camera_zoom_delta(delta_dist: float) -> void:
	if cam_holder == null or is_equal_approx(delta_dist, 0.0):
		return
	var spring := cam_holder.get_node_or_null("%SpringArm3D") as SpringArm3D
	if spring == null:
		return
	spring.spring_length = clampf(
		spring.spring_length + delta_dist,
		cam_holder.min_spring_length,
		cam_holder.max_spring_length,
	)
