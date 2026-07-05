extends Node3D
## Fixed isometric camera rig — follows target on XZ, locked rotation (PROJECT.md §3).

@onready var _camera: Camera3D = $Camera3D

var _target: Node3D = null
var _snap_next := false


func _ready() -> void:
	rotation_degrees = Vector3(Config.CAMERA_PITCH, Config.CAMERA_YAW, 0.0)
	_camera.fov = Config.CAMERA_FOV
	_camera.position = Vector3(0.0, 0.0, Config.CAMERA_DISTANCE)
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


func _apply_follow(weight: float) -> void:
	var target_pos := _target.global_position + Vector3(0.0, Config.CAMERA_CHEST_HEIGHT, 0.0)
	global_position = global_position.lerp(target_pos, weight)
