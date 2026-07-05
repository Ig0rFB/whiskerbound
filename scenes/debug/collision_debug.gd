extends Node3D
## Draws solid collision cells for designer tuning (toggle H).

var _grid: CollisionGrid
var _mesh_root: Node3D


func _ready() -> void:
	_mesh_root = Node3D.new()
	_mesh_root.name = "DebugMeshes"
	add_child(_mesh_root)
	visible = false


func setup(grid: CollisionGrid) -> void:
	_grid = grid
	_rebuild()


func set_overlay_visible(show_it: bool) -> void:
	visible = show_it


func toggle() -> void:
	set_overlay_visible(not visible)


func _rebuild() -> void:
	for child in _mesh_root.get_children():
		child.queue_free()
	if _grid == null:
		return

	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(_grid.cell_size * 0.92, 0.08, _grid.cell_size * 0.92)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Config.COLOR_COLLISION_DEBUG
	mat.no_depth_test = true

	for z in _grid.height:
		for x in _grid.width:
			if not _grid.is_cell_solid(x, z):
				continue
			var tile := MeshInstance3D.new()
			tile.mesh = tile_mesh
			tile.set_surface_override_material(0, mat)
			tile.position = CollisionGrid.cell_center_3d(Vector2i(x, z), _grid.cell_size, 0.06)
			_mesh_root.add_child(tile)
