class_name DepthSort
## Bias visual Y by world Z so southern (+Z) characters draw in front (isometric Y-sort).


static func apply_to_mesh(mesh: MeshInstance3D, base_height: float, world_z: float) -> void:
	mesh.position.y = base_height + world_z * 0.01
