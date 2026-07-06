@tool
extends Node3D
## Fixed camera rig — follows target on XZ; zoom morphs pitch toward third-person (PROJECT.md §3).

var _camera: Camera3D
var _target: Node3D = null
var _snap_next := false
var _distance := 18.0
var _look_height := 0.9
var _preview_pitch_far := -42.0
var _preview_pitch_near := -18.0


func _ready() -> void:
	_ensure_camera()
	if Engine.is_editor_hint():
		_preview_pitch_far = Config.CAMERA_PITCH_FAR
		_preview_pitch_near = Config.CAMERA_PITCH_NEAR
		_apply_preview_pose()
		_try_bind_preview_target()
	else:
		_distance = Config.CAMERA_DISTANCE
		_apply_zoom_pose()
		if _camera:
			_camera.current = true


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_apply_preview_pose()


func set_preview_distance(dist: float) -> void:
	_distance = clampf(dist, _distance_min(), _distance_max())
	if Engine.is_editor_hint():
		_apply_preview_pose()
	else:
		_apply_zoom_pose()
		_snap_to_target()


func set_preview_pitches(far: float, near: float) -> void:
	_preview_pitch_far = far
	_preview_pitch_near = near
	if Engine.is_editor_hint():
		_apply_preview_pose()


func get_preview_distance() -> float:
	return _distance


func get_current_pitch_degrees() -> float:
	var blend := _zoom_blend()
	return lerpf(_pitch_far(), _pitch_near(), blend)


func set_target(node: Node3D, snap: bool = false) -> void:
	_target = node
	_snap_next = snap
	if snap and _target != null:
		_apply_follow(1.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_poll_zoom_input(delta)
	if _target == null:
		return

	var t := 1.0 if _snap_next else clampf(Config.CAMERA_FOLLOW_SPEED * delta, 0.0, 1.0)
	_snap_next = false
	_apply_follow(t)


func _poll_zoom_input(delta: float) -> void:
	var axis := InputActions.camera_zoom_axis
	if absf(axis) > 0.001:
		_adjust_distance(axis * Config.CAMERA_ZOOM_SPEED * delta)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if not event is InputEventMouseButton or not event.pressed:
		return

	var delta_dist := 0.0
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			delta_dist = -Config.CAMERA_ZOOM_STEP
		MOUSE_BUTTON_WHEEL_DOWN:
			delta_dist = Config.CAMERA_ZOOM_STEP
		_:
			return

	_adjust_distance(delta_dist)
	get_viewport().set_input_as_handled()


func _adjust_distance(delta_dist: float) -> void:
	var new_distance := clampf(
		_distance + delta_dist,
		_distance_min(),
		_distance_max(),
	)
	if is_equal_approx(new_distance, _distance):
		return

	_distance = new_distance
	_apply_zoom_pose()
	_snap_to_target()


func _apply_preview_pose() -> void:
	_ensure_camera()
	_apply_zoom_pose()
	if _target != null:
		_apply_follow(1.0)


func _try_bind_preview_target() -> void:
	var root := get_tree().edited_scene_root if Engine.is_editor_hint() else null
	if root == null:
		return
	var target := root.get_node_or_null("PlayerTarget") as Node3D
	if target:
		set_target(target, true)


func _zoom_blend() -> float:
	return inverse_lerp(_distance_max(), _distance_min(), _distance)


func _apply_zoom_pose() -> void:
	_ensure_camera()
	if _camera == null:
		return

	var blend := _zoom_blend()
	var pitch := lerpf(_pitch_far(), _pitch_near(), blend)
	rotation_degrees = Vector3(pitch, _yaw(), 0.0)
	_look_height = lerpf(_chest_far(), _chest_near(), blend)
	_camera.position = Vector3(0.0, 0.0, _distance)
	_camera.fov = lerpf(_fov_far(), _fov_near(), blend)


func _ensure_camera() -> void:
	if _camera == null and has_node("Camera3D"):
		_camera = $Camera3D


func _snap_to_target() -> void:
	_snap_next = true
	if _target != null:
		_apply_follow(1.0)


func _apply_follow(weight: float) -> void:
	if _target == null:
		return
	var target_pos := _target.global_position + Vector3(0.0, _look_height, 0.0)
	global_position = global_position.lerp(target_pos, weight)


func _distance_min() -> float:
	return Config.CAMERA_DISTANCE_MIN if not Engine.is_editor_hint() else 5.0


func _distance_max() -> float:
	return Config.CAMERA_DISTANCE_MAX if not Engine.is_editor_hint() else 26.0


func _pitch_far() -> float:
	if Engine.is_editor_hint():
		return _preview_pitch_far
	return Config.CAMERA_PITCH_FAR


func _pitch_near() -> float:
	if Engine.is_editor_hint():
		return _preview_pitch_near
	return Config.CAMERA_PITCH_NEAR


func _yaw() -> float:
	return Config.CAMERA_YAW if not Engine.is_editor_hint() else 0.0


func _chest_far() -> float:
	return Config.CAMERA_CHEST_HEIGHT_FAR if not Engine.is_editor_hint() else 0.9


func _chest_near() -> float:
	return Config.CAMERA_CHEST_HEIGHT_NEAR if not Engine.is_editor_hint() else 1.3


func _fov_far() -> float:
	return Config.CAMERA_FOV if not Engine.is_editor_hint() else 38.0


func _fov_near() -> float:
	return Config.CAMERA_FOV_NEAR if not Engine.is_editor_hint() else 42.0
