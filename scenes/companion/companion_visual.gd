@tool
class_name CompanionVisual
extends Node3D
## Presentation for the cat companion: fits the `cat.glb` mesh to the body, drives the walk
## animation, and faces the movement direction. Owned by the `Visual` child so the body script
## (`companion.gd`) stays focused on motor + brain (PROJECT.md §9.2).

@onready var _model: Node3D = $Model

var _anim: AnimationPlayer
var _model_fitted := false


## Feet sit on the capsule; GPU depth handles draw order (PROJECT.md §4).
func align_feet() -> void:
	position.y = 0.0


## Force the next fit_model() to re-fit (after (re)spawn or an editor transform change).
func reset_fit() -> void:
	_model_fitted = false


func is_fitted() -> bool:
	return _model_fitted


## Scale `cat.glb` to the target height and sit its AABB bottom on the visual root.
func fit_model() -> void:
	if _model == null or _model_fitted or not is_inside_tree():
		return

	_model.scale = Vector3.ONE
	_model.position = Vector3.ZERO
	_model.rotation = Vector3.ZERO

	var mesh := _find_first_mesh(_model)
	if mesh == null:
		push_warning("Companion: no mesh in cat.glb")
		return

	var local: AABB = mesh.get_aabb()
	if local.size.y < 0.001:
		push_warning("Companion: mesh bounds are empty")
		return

	var fit_scale := Config.COMPANION_MODEL_TARGET_HEIGHT / local.size.y
	_model.scale = Vector3.ONE * fit_scale
	# Align mesh AABB bottom to the visual root, then lift slightly above the floor plane.
	_model.position.y = -local.position.y * fit_scale + Config.COMPANION_MESH_FLOOR_CLEARANCE
	_anim = _find_animation_player(_model)
	_tweak_mesh_material(mesh)
	_model_fitted = true


## Rotate to face the movement direction (feet space; +Y is world south +Z).
func face(move_delta: Vector2) -> void:
	if move_delta.length_squared() < 0.0001:
		return
	rotation.y = atan2(move_delta.x, move_delta.y) + Config.COMPANION_MODEL_YAW_OFFSET


## Play/pause the walk clip and scale its pace to the move speed.
func set_walk(moving: bool, move_speed: float) -> void:
	if _anim == null:
		return
	if not moving:
		if _anim.is_playing():
			_anim.pause()
		return
	if _anim.current_animation != Config.COMPANION_WALK_ANIM:
		_anim.play(Config.COMPANION_WALK_ANIM)
	var pace := clampf(move_speed / Config.COMPANION_SPEED, 0.15, 1.5)
	_anim.speed_scale = pace * Config.COMPANION_WALK_ANIM_SPEED


## Fitted mesh metrics for headless visual tests (the body adds body-level fields).
func debug_state() -> Dictionary:
	var mesh := _find_first_mesh(_model) if _model else null
	var state := {
		"model_fitted": _model_fitted,
		"mesh_visible": mesh.visible if mesh else false,
		"has_skin": mesh.skin != null if mesh else false,
		"has_walk_anim": _anim != null and _anim.has_animation(Config.COMPANION_WALK_ANIM),
		"model_scale": _model.scale if _model else Vector3.ZERO,
		"model_pos": _model.position if _model else Vector3.ZERO,
		"visual_pos": position,
	}
	if mesh != null:
		state["mesh_aabb"] = _global_mesh_aabb(mesh)
		state["mesh_local_aabb"] = mesh.get_aabb()
		var mat: Material = mesh.get_surface_override_material(0)
		if mat == null:
			mat = mesh.get_active_material(0)
		state["material"] = mat
	return state


func _tweak_mesh_material(mesh: MeshInstance3D) -> void:
	var mat: Material = mesh.get_active_material(0)
	if mat == null:
		return
	var std := mat.duplicate() as StandardMaterial3D
	std.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	std.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.set_surface_override_material(0, std)


func _global_mesh_aabb(mesh: MeshInstance3D) -> AABB:
	var box := AABB()
	var first := true
	var gt := mesh.global_transform
	var local: AABB = mesh.get_aabb()
	for i in 8:
		var corner: Vector3 = gt * local.get_endpoint(i)
		if first:
			box = AABB(corner, Vector3.ZERO)
			first = false
		else:
			box = box.expand(corner)
	return box


func _find_first_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_first_mesh(child)
		if found != null:
			return found
	return null


func _find_animation_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for child in root.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null
