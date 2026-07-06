class_name DepthSort
## Bias visual Y by world Z so southern (+Z) characters draw in front (isometric Y-sort).


static func apply_to_visual(node: Node3D, base_height: float, world_z: float) -> void:
	node.position.y = base_height + world_z * 0.01


## Back-compat alias — companions now use a model root Node3D.
static func apply_to_mesh(mesh: Node3D, base_height: float, world_z: float) -> void:
	apply_to_visual(mesh, base_height, world_z)
