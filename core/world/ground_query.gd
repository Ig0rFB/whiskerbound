class_name GroundQuery
extends RefCounted
## Physics ray helpers — snap companions to 3D playground geometry.

const WORLD_MASK := 1
const RAY_TOP := 64.0
const RAY_DEPTH := 128.0


static func ground_y_at(from_node: Node3D, feet_x: float, feet_z: float) -> float:
	var world := from_node.get_world_3d()
	if world == null:
		return 0.0

	var space := world.direct_space_state
	var origin := Vector3(feet_x, RAY_TOP, feet_z)
	var target := Vector3(feet_x, RAY_TOP - RAY_DEPTH, feet_z)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = WORLD_MASK
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return 0.0
	return float(hit.position.y)


static func clamp_feet_move(
	from_node: Node3D,
	from_feet: Vector2,
	to_feet: Vector2,
	body_radius: float = 0.22,
) -> Vector2:
	if from_feet.distance_squared_to(to_feet) < 0.000001:
		return to_feet

	var world := from_node.get_world_3d()
	if world == null:
		return to_feet

	var from_y := ground_y_at(from_node, from_feet.x, from_feet.y) + 0.3
	var to_y := ground_y_at(from_node, to_feet.x, to_feet.y) + 0.3
	var origin := Vector3(from_feet.x, from_y, from_feet.y)
	var end := Vector3(to_feet.x, to_y, to_feet.y)
	var delta := end - origin
	var distance := delta.length()
	if distance < 0.001:
		return to_feet

	var space := world.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		origin + delta.normalized() * (distance + body_radius),
	)
	query.collision_mask = WORLD_MASK
	query.collide_with_bodies = true

	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return to_feet

	var safe: Vector3 = hit.position - delta.normalized() * (body_radius + 0.08)
	return Vector2(safe.x, safe.z)
