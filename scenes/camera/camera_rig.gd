extends Node3D
## Fixed isometric camera rig — follows target on XZ, locked rotation (PROJECT.md §3).

@onready var _camera: Camera3D = $Camera3D

var _target: Node3D = null
var _snap_next := false
var _distance := Config.CAMERA_DISTANCE


func _ready() -> void:
	rotation_degrees = Vector3(Config.CAMERA_PITCH, Config.CAMERA_YAW, 0.0)
	_camera.fov = Config.CAMERA_FOV
	_apply_distance()
	_camera.current = true


func set_target(node: Node3D, snap: bool = false) -> void:
	_target = node
	_snap_next = snap
	if snap and _target != null:
		_apply_follow(1.0)


func _process(delta: float) -> void:
	if _target == null:
		return

	var t := 1.0 if _snap_next else clampf(Config.CAMERA_FOLLOW_SPEED * delta, 0.0, 1.0)
	_snap_next = false
	_apply_follow(t)


func _unhandled_input(event: InputEvent) -> void:
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

	var new_distance := clampf(
		_distance + delta_dist,
		Config.CAMERA_DISTANCE_MIN,
		Config.CAMERA_DISTANCE_MAX
	)
	if is_equal_approx(new_distance, _distance):
		return

	_distance = new_distance
	_apply_distance()
	_snap_to_target()
	get_viewport().set_input_as_handled()


func _apply_distance() -> void:
	_camera.position = Vector3(0.0, 0.0, _distance)


func _snap_to_target() -> void:
	_snap_next = true
	if _target != null:
		_apply_follow(1.0)


func _apply_follow(weight: float) -> void:
	var target_pos := _target.global_position + Vector3(0.0, Config.CAMERA_CHEST_HEIGHT, 0.0)
	global_position = global_position.lerp(target_pos, weight)
