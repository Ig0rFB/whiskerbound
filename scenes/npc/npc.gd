extends GroundedCharacter
## NPC marker in the world — grounded body + interact dialogue (PROJECT.md §9.3).

enum MotionKind { GROUNDED, FLOATING }

@export var npc_id: String = ""
@export var dialogue_id: int = -1
@export var display_name: String = "???"
@export var motion_kind: MotionKind = MotionKind.GROUNDED

@onready var _visual: MeshInstance3D = $Visual


func _ready() -> void:
	if motion_kind == MotionKind.FLOATING:
		body_radius = Config.NPC_FLOATING_BODY_RADIUS
		body_height = Config.NPC_FLOATING_BODY_HEIGHT
	else:
		body_radius = Config.NPC_BODY_RADIUS
		body_height = Config.NPC_BODY_HEIGHT
	super._ready()
	if motion_kind == MotionKind.FLOATING:
		motion_mode = MOTION_MODE_FLOATING
	add_to_group("npcs")
	_hide_placeholder_if_skinned()
	if dialogue_id < 0 and not npc_id.is_empty():
		dialogue_id = DialogueData.dialogue_id_for_npc(npc_id)
	if display_name == "???" and dialogue_id >= 0:
		display_name = DialogueData.speaker_name(dialogue_id)


func _physics_process(_delta: float) -> void:
	if motion_kind == MotionKind.FLOATING:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# Static NPCs — keep feet on moving platforms / slopes without drifting.
	velocity.x = 0.0
	velocity.z = 0.0
	apply_gravity(_delta)
	move_and_slide()
	DepthSort.apply_to_mesh(_visual, Config.NPC_BODY_HEIGHT * 0.35, global_position.z)


func snap_to_floor() -> void:
	if motion_kind == MotionKind.FLOATING:
		return
	super.snap_to_floor()


func _hide_placeholder_if_skinned() -> void:
	for child in get_children():
		if child == _visual or child is CollisionShape3D:
			continue
		if child.name == "Interactable":
			continue
		if child is Node3D:
			_visual.visible = false
			return
