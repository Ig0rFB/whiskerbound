extends "res://core/world/grounded_character.gd"
## NPC marker in the world — grounded body + interact dialogue (PROJECT.md §9.3).

@export var npc_id: String = ""
@export var dialogue_id: int = -1
@export var display_name: String = "???"

@onready var _visual: MeshInstance3D = $Visual


func _ready() -> void:
	body_radius = Config.NPC_BODY_RADIUS
	body_height = Config.NPC_BODY_HEIGHT
	super._ready()
	add_to_group("npcs")
	if dialogue_id < 0 and not npc_id.is_empty():
		dialogue_id = DialogueData.dialogue_id_for_npc(npc_id)
	if display_name == "???" and dialogue_id >= 0:
		display_name = DialogueData.speaker_name(dialogue_id)


func _physics_process(_delta: float) -> void:
	# Static NPCs — keep feet on moving platforms / slopes without drifting.
	velocity.x = 0.0
	velocity.z = 0.0
	apply_gravity(_delta)
	move_and_slide()
	DepthSort.apply_to_mesh(_visual, Config.NPC_BODY_HEIGHT * 0.35, global_position.z)
