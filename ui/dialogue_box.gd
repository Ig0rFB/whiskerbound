extends Control
## Dialogue panel — speaker, portrait placeholder, line text.

@onready var _speaker_label: Label = $Panel/Margin/VBox/Header/SpeakerLabel
@onready var _portrait: ColorRect = $Panel/Margin/VBox/Header/Portrait
@onready var _line_label: Label = $Panel/Margin/VBox/LineLabel
@onready var _hint_label: Label = $Panel/Margin/VBox/HintLabel


func _ready() -> void:
	visible = false
	_portrait.color = Color("#9B8FA8")


func show_dialogue(speaker: String, line_text: String, is_last_line: bool) -> void:
	visible = true
	_speaker_label.text = speaker
	_line_label.text = line_text
	_hint_label.text = "Press E to continue" if not is_last_line else "Press E to close"


func hide_dialogue() -> void:
	visible = false
