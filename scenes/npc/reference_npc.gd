extends "res://scenes/npc/reference/NPCBody.gd"
## Reference BaseNPC physics + Whiskerbound dialogue metadata.


@export var npc_id: String = ""
@export var dialogue_id: int = -1
@export var display_name: String = "???"


func _ready() -> void:
	super._ready()
	add_to_group("npcs")
	if dialogue_id < 0 and not npc_id.is_empty():
		dialogue_id = DialogueData.dialogue_id_for_npc(npc_id)
	if display_name == "???" and dialogue_id >= 0:
		display_name = DialogueData.speaker_name(dialogue_id)
