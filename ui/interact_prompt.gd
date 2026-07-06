extends Control
## Interact prompt when an NPC is in range.

@onready var _label: Label = $Label


func _ready() -> void:
	visible = false
	_refresh_prompt_text()


func set_show_prompt(show_it: bool) -> void:
	visible = show_it


func _refresh_prompt_text() -> void:
	if _label == null:
		return
	_label.text = "Press E or A to talk"
