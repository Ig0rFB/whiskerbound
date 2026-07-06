class_name InteractionLogic
## Camera-ray interaction queries (reference untitled-game pattern).
##
## The player's InteractionRaycast uses mask 3 (layers 1 + 2) per reference untitled-game.

const INTERACT_RADIUS := Config.INTERACT_RADIUS


## NPC under the raycast collider, if it is a registered scene NPC.
static func find_npc_from_ray(ray_collider: Object, npcs: Array) -> Node3D:
	var hit_npc := npc_from_collider(ray_collider)
	if hit_npc == null:
		return null
	for npc in npcs:
		if npc == hit_npc:
			return hit_npc
	return null


## Walks up from a physics collider to the owning NPC (group `npcs`).
static func npc_from_collider(collider: Object) -> Node3D:
	var node: Node = collider as Node
	while node != null:
		if node.is_in_group("npcs") and node is Node3D:
			return node as Node3D
		node = node.get_parent()
	return null


## Nearest NPC within interact radius — used by smoke tests and legacy helpers.
static func find_nearest_npc(player_feet: Vector2, npcs: Array) -> Node3D:
	var best: Node3D = null
	var radius_sq := INTERACT_RADIUS * INTERACT_RADIUS
	var best_dist_sq := radius_sq + 1.0

	for npc in npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		if not (npc is Node3D) or not (npc as Node3D).is_inside_tree():
			continue
		var npc_feet := Vector2(npc.global_position.x, npc.global_position.z)
		var dist_sq := player_feet.distance_squared_to(npc_feet)
		if dist_sq <= radius_sq and dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = npc as Node3D

	return best


static func player_near_npc(player_feet: Vector2, npcs: Array) -> bool:
	return find_nearest_npc(player_feet, npcs) != null
