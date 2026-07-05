extends Node3D
## Draws companion A* paths on the ground when debug HUD is on.

const PATH_COLORS := [
	Color(1.0, 0.7, 0.31, 0.86),
	Color(1.0, 0.47, 0.78, 0.86),
	Color(0.47, 0.86, 1.0, 0.86),
	Color(0.7, 1.0, 0.47, 0.86),
]
const LINE_HEIGHT := 0.07
const LINE_WIDTH := 0.08

var _mesh_root: Node3D


func _ready() -> void:
	_mesh_root = Node3D.new()
	_mesh_root.name = "PathMeshes"
	add_child(_mesh_root)
	visible = false


func set_overlay_visible(show_it: bool) -> void:
	visible = show_it


func _process(_delta: float) -> void:
	if not visible:
		return
	_rebuild()


func _rebuild() -> void:
	for child in _mesh_root.get_children():
		child.queue_free()

	for companion in GameState.companions:
		if companion == null or not is_instance_valid(companion):
			continue
		if not companion.has_method("get_debug_path"):
			continue
		_draw_companion_path(companion)


func _draw_companion_path(companion: Node3D) -> void:
	var path: PackedVector2Array = companion.get_debug_path()
	if path.is_empty():
		return

	var draw_path := path.duplicate()
	var feet := Vector2(companion.global_position.x, companion.global_position.z)
	if draw_path[0].distance_squared_to(feet) > 0.01:
		draw_path.insert(0, feet)

	if draw_path.size() < 2:
		_add_waypoint_marker(draw_path[0], PATH_COLORS[0])
		return

	var slot: int = companion.get_debug_slot() if companion.has_method("get_debug_slot") else 0
	var colour: Color = PATH_COLORS[slot % PATH_COLORS.size()]

	for i in draw_path.size() - 1:
		_add_segment(draw_path[i], draw_path[i + 1], colour)

	for waypoint in draw_path:
		_add_waypoint_marker(waypoint, colour)


func _add_segment(from_feet: Vector2, to_feet: Vector2, colour: Color) -> void:
	var delta := to_feet - from_feet
	var length := delta.length()
	if length < 0.01:
		return

	var segment := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(LINE_WIDTH, 0.04, length)
	segment.mesh = mesh
	segment.position = Vector3(
		(from_feet.x + to_feet.x) * 0.5,
		LINE_HEIGHT,
		(from_feet.y + to_feet.y) * 0.5,
	)
	segment.rotation.y = atan2(delta.x, delta.y)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = colour
	mat.no_depth_test = true
	segment.set_surface_override_material(0, mat)
	_mesh_root.add_child(segment)


func _add_waypoint_marker(feet: Vector2, colour: Color) -> void:
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.16
	marker.mesh = mesh
	marker.position = Vector3(feet.x, LINE_HEIGHT + 0.02, feet.y)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = colour.lightened(0.15)
	mat.no_depth_test = true
	marker.set_surface_override_material(0, mat)
	_mesh_root.add_child(marker)
