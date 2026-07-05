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
