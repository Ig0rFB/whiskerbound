extends Control
## Pause overlay — resume or quit (Esc).

signal resume_requested
signal quit_requested

@onready var _panel: PanelContainer = $Panel
@onready var _resume_button: Button = $Panel/Margin/VBox/ResumeButton
@onready var _quit_button: Button = $Panel/Margin/VBox/QuitButton


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_resume_button.pressed.connect(_on_resume_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func open() -> void:
	visible = true
	_resume_button.grab_focus()


func close() -> void:
	visible = false


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()
