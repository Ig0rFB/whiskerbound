extends Control
## "Press E" prompt when an NPC is in range.


func _ready() -> void:
	visible = false


func set_show_prompt(show_it: bool) -> void:
	visible = show_it
