extends SceneTree
## Headless companion mesh assertions — run: bash scripts/run_companion_visual_test.sh

const TARGET_HEIGHT := 0.4
const MIN_MESH_HEIGHT := 0.25
const MAX_MESH_HEIGHT := 0.55
const MIN_MODEL_SCALE := 0.001


func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		_fail("Failed to load main.tscn")

	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var game_state: Node = root.get_node("GameState")
	var companion: Node = game_state.companion
	if companion == null:
		_fail("GameState.companion is null")

	if not companion.has_method("get_visual_debug_state"):
		_fail("Companion missing get_visual_debug_state()")

	var state: Dictionary = companion.get_visual_debug_state()
	var bind: AABB = state.get("mesh_aabb", AABB())
	var mat: Material = state.get("material")

	print("COMPANION_VISUAL: companion_pos=", companion.global_position)
	print("COMPANION_VISUAL: state=", state)

	if not state.get("model_fitted", false):
		_fail("Model was not fitted")

	if not state.get("mesh_visible", false):
		_fail("Companion mesh is not visible")

	if not state.get("has_skin", false):
		_fail("Companion mesh has no skin (expected animated GLB)")

	if not state.get("has_walk_anim", false):
		_fail("Companion missing walk animation")

	var model_scale: Vector3 = state.get("model_scale", Vector3.ZERO)
	if model_scale.x < MIN_MODEL_SCALE:
		_fail("Model scale %.4f is too small — armature scale likely still broken" % model_scale.x)

	if bind.size.y < MIN_MESH_HEIGHT or bind.size.y > MAX_MESH_HEIGHT:
		_fail(
			"Mesh height %.3f outside [%.2f, %.2f]"
			% [bind.size.y, MIN_MESH_HEIGHT, MAX_MESH_HEIGHT]
		)

	if bind.position.y < -0.05:
		_fail("Mesh bottom below ground: bind.position.y=%.3f" % bind.position.y)

	var top_y := bind.position.y + bind.size.y
	if top_y > 1.5:
		_fail("Mesh top too high: %.3f" % top_y)

	if mat is StandardMaterial3D:
		var std := mat as StandardMaterial3D
		if std.albedo_texture == null:
			_fail("Material has no albedo texture")
		if std.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			_fail("Material transparency is enabled")
	else:
		_fail("Expected StandardMaterial3D override on mesh surface 0")

	print("COMPANION_VISUAL_OK")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
