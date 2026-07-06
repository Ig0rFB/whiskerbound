extends Control
## Short speech bubble above a companion (meow / bark).


@onready var _panel: PanelContainer = $PanelContainer
@onready var _label: Label = $PanelContainer/Label

var _companion: Node3D
var _timer: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.companion_barked.connect(_on_companion_barked)


func _process(delta: float) -> void:
	if not visible:
		return
	_timer -= delta
	if _timer <= 0.0:
		visible = false
		return
	_follow_companion()


func show_bark(companion: Node3D, text: String) -> void:
	_companion = companion
	_label.text = text
	_timer = Config.COMPANION_BARK_DURATION
	visible = true
	_follow_companion()


func _on_companion_barked(companion: Node3D, text: String) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		return
	show_bark(companion, text)


func _follow_companion() -> void:
	if _companion == null or not is_instance_valid(_companion):
		visible = false
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var world_pos := _companion.global_position + Vector3(0.0, Config.COMPANION_BODY_HEIGHT + 0.25, 0.0)
	if camera.is_position_behind(world_pos):
		visible = false
		return
	var screen_pos: Vector2 = camera.unproject_position(world_pos)
	var half := _panel.size * 0.5
	position = screen_pos - Vector2(half.x, _panel.size.y + 8.0)
