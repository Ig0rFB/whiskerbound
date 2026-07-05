extends Node3D
## NPC marker in the world — interact to open dialogue (PROJECT.md §9.3).

@export var npc_id: String = ""
@export var dialogue_id: int = -1
@export var display_name: String = "???"

@onready var _visual: MeshInstance3D = $Visual


func _ready() -> void:
	add_to_group("npcs")
	if dialogue_id < 0 and not npc_id.is_empty():
		dialogue_id = DialogueData.dialogue_id_for_npc(npc_id)
	if display_name == "???" and dialogue_id >= 0:
		display_name = DialogueData.speaker_name(dialogue_id)


func _process(_delta: float) -> void:
	DepthSort.apply_to_mesh(_visual, 0.25, global_position.z)
