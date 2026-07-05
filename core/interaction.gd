class_name InteractionLogic
## NPC proximity queries — pure logic (ported from 2D prototype interaction.odin).

const INTERACT_RADIUS := 1.5


static func find_nearest_npc(player_feet: Vector2, npcs: Array) -> Node3D:
	var best: Node3D = null
	var radius_sq := INTERACT_RADIUS * INTERACT_RADIUS
	var best_dist_sq := radius_sq + 1.0

	for npc in npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var npc_feet := Vector2(npc.global_position.x, npc.global_position.z)
		var dist_sq := player_feet.distance_squared_to(npc_feet)
		if dist_sq <= radius_sq and dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = npc

	return best


static func player_near_npc(player_feet: Vector2, npcs: Array) -> bool:
	return find_nearest_npc(player_feet, npcs) != null
