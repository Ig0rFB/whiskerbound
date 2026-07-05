class_name Movement
## Pure movement helpers — no Node dependency (ported from 2D prototype movement.odin).


static func normalise_input(v: Vector2) -> Vector2:
	if v.length_squared() <= 0.0:
		return Vector2.ZERO
	if v.length_squared() <= 1.0:
		return v
	return v.normalized()


## Separate X then Z resolution for wall sliding. Vector2 uses (world_x, world_z).
static func apply_velocity(
	grid: CollisionGrid,
	feet_pos: Vector2,
	velocity: Vector2,
	collider: Rect2,
	delta: float,
) -> Vector2:
	var result := feet_pos
	var delta_pos := velocity * delta

	var new_x := result.x + delta_pos.x
	if not grid.entity_blocked(new_x, result.y, collider):
		result.x = new_x

	var new_z := result.y + delta_pos.y
	if not grid.entity_blocked(result.x, new_z, collider):
		result.y = new_z

	return result
