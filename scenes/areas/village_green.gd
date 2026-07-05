extends Node3D
## First playable area — placeholder tile ground and spawn markers (PROJECT.md §10).

const AREA_WIDTH := 20
const AREA_HEIGHT := 16

@onready var _ground_root: Node3D = $Ground


func _ready() -> void:
	_build_ground_tiles()
	_build_border_walls()
	_build_trees()


func get_player_spawn_global() -> Vector3:
	return $PlayerSpawn.global_position


func _build_ground_tiles() -> void:
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(Config.GRID_CELL, 0.1, Config.GRID_CELL)

	var ground_mat := StandardMaterial3D.new()
	ground_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground_mat.albedo_color = Config.COLOR_GROUND

	for x in AREA_WIDTH:
		for z in AREA_HEIGHT:
			var tile := MeshInstance3D.new()
			tile.mesh = tile_mesh
			tile.set_surface_override_material(0, ground_mat)
			tile.position = Vector3(
				float(x) + 0.5,
				-0.05,
				float(z) + 0.5,
			)
			_ground_root.add_child(tile)


func _build_border_walls() -> void:
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(Config.GRID_CELL, 1.0, Config.GRID_CELL)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_mat.albedo_color = Config.COLOR_STONE

	for x in AREA_WIDTH:
		_add_wall(wall_mesh, wall_mat, x, -1)
		_add_wall(wall_mesh, wall_mat, x, AREA_HEIGHT)

	for z in range(AREA_HEIGHT):
		_add_wall(wall_mesh, wall_mat, -1, z)
		_add_wall(wall_mesh, wall_mat, AREA_WIDTH, z)


func _add_wall(mesh: BoxMesh, mat: StandardMaterial3D, x: int, z: int) -> void:
	var wall := MeshInstance3D.new()
	wall.mesh = mesh
	wall.set_surface_override_material(0, mat)
	wall.position = Vector3(float(x) + 0.5, 0.45, float(z) + 0.5)
	_ground_root.add_child(wall)


func _build_trees() -> void:
	var decor := $Decor
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trunk_mat.albedo_color = Color("#8B6914")

	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leaf_mat.albedo_color = Color("#5A9E5A")

	for pos in [Vector3(4, 0, 5), Vector3(15, 0, 11), Vector3(7, 0, 12)]:
		_add_tree(decor, pos, trunk_mat, leaf_mat)


func _add_tree(
	parent: Node3D,
	pos: Vector3,
	trunk_mat: StandardMaterial3D,
	leaf_mat: StandardMaterial3D,
) -> void:
	var tree := Node3D.new()
	tree.position = pos
	parent.add_child(tree)

	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.15
	trunk_mesh.height = 0.5
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0, 0.25, 0)
	trunk.set_surface_override_material(0, trunk_mat)
	tree.add_child(trunk)

	var leaves := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.55
	leaf_mesh.height = 1.0
	leaves.mesh = leaf_mesh
	leaves.position = Vector3(0, 0.75, 0)
	leaves.set_surface_override_material(0, leaf_mat)
	tree.add_child(leaves)
