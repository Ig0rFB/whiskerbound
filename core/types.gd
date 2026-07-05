class_name GameTypes
## Shared enums and helpers — no Node dependency (PROJECT.md §6.1).

enum Direction8 {
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
}


static func facing_world_delta(facing: Direction8) -> Vector2:
	match facing:
		Direction8.NORTH:
			return Vector2(0, -1)
		Direction8.NORTH_EAST:
			return Vector2(1, -1)
		Direction8.EAST:
			return Vector2(1, 0)
		Direction8.SOUTH_EAST:
			return Vector2(1, 1)
		Direction8.SOUTH:
			return Vector2(0, 1)
		Direction8.SOUTH_WEST:
			return Vector2(-1, 1)
		Direction8.WEST:
			return Vector2(-1, 0)
		Direction8.NORTH_WEST:
			return Vector2(-1, -1)
	return Vector2(0, 1)


static func facing_from_vector(v: Vector2, last_facing: Direction8) -> Direction8:
	if v.length_squared() < 0.0001:
		return last_facing

	var ax := absf(v.x)
	var az := absf(v.y)
	var t := 0.41421356237

	if az < ax * t:
		if v.x > 0.0:
			return Direction8.EAST
		return Direction8.WEST
	if ax < az * t:
		if v.y > 0.0:
			return Direction8.SOUTH
		return Direction8.NORTH
	if v.x > 0.0 and v.y < 0.0:
		return Direction8.NORTH_EAST
	if v.x > 0.0 and v.y > 0.0:
		return Direction8.SOUTH_EAST
	if v.x < 0.0 and v.y > 0.0:
		return Direction8.SOUTH_WEST
	return Direction8.NORTH_WEST


static func yaw_from_facing(facing: Direction8) -> float:
	match facing:
		Direction8.SOUTH:
			return 0.0
		Direction8.SOUTH_EAST:
			return -PI * 0.25
		Direction8.EAST:
			return -PI * 0.5
		Direction8.NORTH_EAST:
			return -PI * 0.75
		Direction8.NORTH:
			return PI
		Direction8.NORTH_WEST:
			return PI * 0.75
		Direction8.WEST:
			return PI * 0.5
		Direction8.SOUTH_WEST:
			return PI * 0.25
	return 0.0
