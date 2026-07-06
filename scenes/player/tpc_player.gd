class_name TpcPlayer
extends PlayerCharacter
## Whiskerbound player — Jeheno third-person controller with companion + UI hooks.
## Not @tool — editor preview is handled by GodotPlushSkin; @tool here spams GameState/camera errors.

const GamepadInputScript := preload("res://input/gamepad.gd")

const LOOK_SENSITIVITY := 9.0
const LOOK_DEADZONE := 0.18

var feet_velocity: Vector2 = Vector2.ZERO

var _last_feet: Vector2 = Vector2.ZERO
var _ray_exceptions_bound: bool = false
var _interaction_ray_hit: bool = false
var _interaction_ray_from: Vector3 = Vector3.ZERO
var _interaction_ray_to: Vector3 = Vector3.ZERO
var _interaction_ray_hit_point: Vector3 = Vector3.ZERO
var _interaction_ray_collider_name: String = ""
var _interaction_ray_collider_layer: int = 0

@onready var _interaction_raycast: RayCast3D = %InteractionRaycast


func _ready() -> void:
	super._ready()
	collision_mask = Config.COLLISION_LAYER_WORLD | Config.COLLISION_LAYER_CHARACTER
	_disable_embedded_hud()
	_disable_addon_camera_zoom()
	if _interaction_raycast == null:
		push_error("TpcPlayer: missing %InteractionRaycast on VisualRoot (check player.tscn)")
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
	if GameState.show_debug_hud:
		_sync_interaction_ray()
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
		_sync_interact_target("", null)
		return
	_handle_interaction()
	super._physics_process(delta)


## Reference untitled-game interaction — ray from VisualRoot, camera-facing basis.
func _handle_interaction() -> void:
	if _interaction_raycast == null or cam_holder == null:
		_sync_interact_target("", null)
		return

	_sync_interaction_ray()

	var target_name := ""
	var interactable_owner: Node = null
	if _interaction_raycast.is_colliding():
		var collider: Object = _interaction_raycast.get_collider()
		if collider is Node:
			interactable_owner = _find_interactable_owner(collider)

		if interactable_owner != null:
			target_name = interactable_owner.name

	_sync_interact_target(target_name, interactable_owner)


func _find_interactable_owner(collider: Object) -> Node:
	var node: Node = collider as Node
	while node != null:
		if node.has_node("Interactable"):
			return node
		node = node.get_parent()
	return null


func _sync_interact_target(target_name: String, target_owner: Node) -> void:
	if GameState.interact_target_name == target_name and GameState.interact_target_owner == target_owner:
		return
	GameState.interact_target_name = target_name
	GameState.interact_target_owner = target_owner
	Events.interact_target_changed.emit(target_name)


## Aligns the interaction ray with the camera and caches debug draw data.
func _sync_interaction_ray() -> void:
	if _interaction_raycast == null or cam_holder == null:
		_interaction_ray_hit = false
		_interaction_ray_collider_name = ""
		_interaction_ray_collider_layer = 0
		return

	_bind_interaction_ray_exceptions()
	# Reference untitled-game: chest origin, camera-facing direction (not full camera transform).
	var camera: Camera3D = cam_holder.cam as Camera3D
	if camera == null:
		_interaction_ray_hit = false
		return
	_interaction_raycast.global_transform.basis = camera.global_transform.basis
	_interaction_raycast.force_raycast_update()

	var ray_length: float = _interaction_raycast.target_position.length()
	var ray_dir: Vector3 = -_interaction_raycast.global_transform.basis.z
	_interaction_ray_from = _interaction_raycast.global_position
	_interaction_ray_to = _interaction_ray_from + ray_dir * ray_length
	_interaction_ray_hit = _interaction_raycast.is_colliding()
	_interaction_ray_hit_point = (
		_interaction_raycast.get_collision_point() if _interaction_ray_hit else _interaction_ray_to
	)
	_interaction_ray_collider_name = ""
	_interaction_ray_collider_layer = 0
	if _interaction_ray_hit:
		var collider: Object = _interaction_raycast.get_collider()
		if collider is CollisionObject3D:
			_interaction_ray_collider_layer = (collider as CollisionObject3D).collision_layer
		if collider is Node:
			_interaction_ray_collider_name = (collider as Node).name


func _bind_interaction_ray_exceptions() -> void:
	if _ray_exceptions_bound:
		return
	_interaction_raycast.add_exception(self)
	var companion: Node = GameState.companion
	if companion is CollisionObject3D:
		_interaction_raycast.add_exception(companion as CollisionObject3D)
	_ray_exceptions_bound = true


## Jeheno locomotion label shown on the debug HUD (`State: Idle`, `Walk`, …).
func get_locomotion_state_name() -> String:
	if state_machine == null:
		return ""
	return state_machine.curr_state_name


## True when the player is in Jeheno `IdleState` — same signal the debug HUD displays.
func is_locomotion_idle() -> bool:
	return get_locomotion_state_name() == "Idle"


func interaction_ray_is_hit() -> bool:
	return _interaction_ray_hit


func interaction_ray_from() -> Vector3:
	return _interaction_ray_from


func interaction_ray_to() -> Vector3:
	return _interaction_ray_to


func interaction_ray_hit_point() -> Vector3:
	return _interaction_ray_hit_point


func interaction_ray_collider_name() -> String:
	return _interaction_ray_collider_name


func interaction_ray_collider_layer() -> int:
	return _interaction_ray_collider_layer


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

	var look_scale := LOOK_SENSITIVITY * delta * cam_holder.mouse_sensibility * 100.0
	cam_holder.rotate_from_vector(look * look_scale)


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
