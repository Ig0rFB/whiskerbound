@tool
extends Node3D
## Editor camera tuner — open `camera_preview.tscn`, select **CameraPreview**.
##
## Picture-in-picture: enable **Little Camera Preview** plugin, select **Camera3D**,
## pin the panel, then select **CameraPreview** to scrub sliders while watching the view.

var _preview_distance := 18.0
var _preview_pitch_far := -42.0
var _preview_pitch_near := -18.0
var _preview_current_pitch := -42.0


func _sync_rig() -> void:
	if not Engine.is_editor_hint():
		return
	var rig := get_node_or_null("CameraRig")
	if rig == null:
		return
	if rig.has_method("set_preview_distance"):
		rig.set_preview_distance(_preview_distance)
	if rig.has_method("set_preview_pitches"):
		rig.set_preview_pitches(_preview_pitch_far, _preview_pitch_near)
	if rig.has_method("get_current_pitch_degrees"):
		_preview_current_pitch = rig.get_current_pitch_degrees()
	notify_property_list_changed()


func _bind_rig() -> void:
	if not Engine.is_editor_hint():
		return
	var target := get_node_or_null("PlayerTarget") as Node3D
	var rig := get_node_or_null("CameraRig")
	if target == null or rig == null or not rig.has_method("set_target"):
		return
	rig.set_target(target, true)


func _apply_preview_distance(value: float) -> void:
	var clamped := clampf(value, Config.CAMERA_DISTANCE_MIN, Config.CAMERA_DISTANCE_MAX)
	if is_equal_approx(_preview_distance, clamped):
		return
	_preview_distance = clamped
	_sync_rig()


func _apply_preview_pitch_far(value: float) -> void:
	var clamped := clampf(value, -89.0, 0.0)
	if is_equal_approx(_preview_pitch_far, clamped):
		return
	_preview_pitch_far = clamped
	_sync_rig()


func _apply_preview_pitch_near(value: float) -> void:
	var clamped := clampf(value, -89.0, 0.0)
	if is_equal_approx(_preview_pitch_near, clamped):
		return
	_preview_pitch_near = clamped
	_sync_rig()


func _load_defaults_from_config() -> void:
	if not Engine.is_editor_hint():
		return
	_preview_distance = Config.CAMERA_DISTANCE
	_preview_pitch_far = Config.CAMERA_PITCH_FAR
	_preview_pitch_near = Config.CAMERA_PITCH_NEAR


@export_group("Camera Tuning")
@export_range(5.0, 26.0, 0.1, "or_greater", "or_lesser")
var preview_distance: float:
	get:
		return _preview_distance
	set(value):
		_apply_preview_distance(value)


@export_range(-89.0, 0.0, 0.5)
var preview_pitch_far: float:
	get:
		return _preview_pitch_far
	set(value):
		_apply_preview_pitch_far(value)


@export_range(-89.0, 0.0, 0.5)
var preview_pitch_near: float:
	get:
		return _preview_pitch_near
	set(value):
		_apply_preview_pitch_near(value)


@export_group("Camera Tuning (read-only)")
@export_range(-89.0, 0.0, 0.1)
var preview_current_pitch: float:
	get:
		return _preview_current_pitch
	set(_value):
		pass


func _ready() -> void:
	_load_defaults_from_config()
	_bind_rig()
	_sync_rig()
