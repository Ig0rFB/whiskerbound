@tool
extends Node3D

class_name GodotPlushSkin
## Godot plush player skin — local assets, Jeheno animation API preserved.

@onready var godot_plush_mesh = $GodotPlushModel/Rig/Skeleton3D/GodotPlushMesh
@onready var physical_bone_simulator_3d = %PhysicalBoneSimulator3D
@onready var animation_tree : AnimationTree = %AnimationTree
@onready var state_machine : AnimationNodeStateMachinePlayback = animation_tree.get(
	"parameters/StateMachine/playback",
)

var ragdoll : bool = false : set = set_ragdoll
var squash_and_stretch := 1.0 : set = set_squash_and_stretch

signal footstep(intensity : float)


func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("apply_editor_preview")
		return
	set_ragdoll(ragdoll)


## Refresh idle pose and materials when the scene is opened in the editor.
func apply_editor_preview() -> void:
	if not is_inside_tree():
		return
	if animation_tree != null:
		animation_tree.active = true
	if state_machine == null and animation_tree != null:
		state_machine = animation_tree.get("parameters/StateMachine/playback")
	set_state("idle")


func set_ragdoll(value : bool) -> void:
	ragdoll = value
	if not is_inside_tree():
		return
	physical_bone_simulator_3d.active = ragdoll
	animation_tree.active = not ragdoll
	if ragdoll:
		physical_bone_simulator_3d.physical_bones_start_simulation()
	else:
		physical_bone_simulator_3d.physical_bones_stop_simulation()


func set_state(state_name : String) -> void:
	if state_machine == null:
		return
	state_machine.travel(state_name)


func set_squash_and_stretch(value : float) -> void:
	squash_and_stretch = value
	var negative := 1.0 + (1.0 - squash_and_stretch)
	godot_plush_mesh.scale = Vector3(negative, squash_and_stretch, negative)


func emit_footstep(intensity : float = 1.0) -> void:
	footstep.emit(intensity)
