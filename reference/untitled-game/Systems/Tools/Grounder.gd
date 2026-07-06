extends Node3D

@export var ray_length: float = 20.0
@export var collision_mask: int = 1


func _ready():
	if Engine.is_editor_hint():
		return

	# We wait for the physics frame to ensure all colliders are properly registered.
	await get_tree().physics_frame

	var exceptions = [self]
	var collider = find_first_collider(self)
	if collider:
		exceptions.append(collider)

	var space_state = get_world_3d().direct_space_state
	# The query parameters for the raycast: from, to, collision mask, and exceptions.
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * ray_length, collision_mask, exceptions)
	var result = space_state.intersect_ray(query)

	if result:
		# If the ray hits something, move this node to the collision point.
		global_position = result.position


func find_first_collider(node: Node) -> Node:
	if node is CollisionObject3D:
		return node
	
	for child in node.get_children():
		var found = find_first_collider(child)
		if found:
			return found
	
	return null
