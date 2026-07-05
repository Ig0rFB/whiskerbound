class_name CompanionLogic
## Pure companion follow logic — ported from 2D prototype companion.odin.

const SPEED := 3.0
const REPATH_INTERVAL := 0.5
const STUCK_SECONDS := 2.0
const STUCK_MOVE_EPS_SQ := 0.0004
const WAYPOINT_REACH_DIST_SQ := 0.08
const PLAYER_REPATH_MOVE_SQ := 4.0
const FOLLOW_DISTANCE_BASE := 1.25


static func follow_distance(slot: int) -> float:
	return FOLLOW_DISTANCE_BASE + float(slot) * 0.45


static func update(
	feet_pos: Vector2,
	player_pos: Vector2,
	player_velocity: Vector2,
	data: CompanionData,
	grid: CollisionGrid,
	astar: AStarGrid2D,
	collider: Rect2,
	slot: int,
	delta: float,
) -> Vector2:
	if grid.center_cell_blocked(feet_pos.x, feet_pos.y):
		data.clear_path()
		data.stuck_timer = 0.0
		return teleport_beside_player(player_pos, player_velocity, grid, collider, slot)

	var follow_dist := follow_distance(slot)
	var goal := _path_goal(player_pos, player_velocity, data)
	var to_player := player_pos - feet_pos
	var player_idle := player_velocity.length_squared() < 0.01

	if player_idle and to_player.length_squared() <= follow_dist * follow_dist:
		data.clear_path()
		data.stuck_timer = 0.0
		data.idle_timer += delta
		return feet_pos

	data.idle_timer = 0.0
	if data.path.is_empty() and data.stuck_timer == 0.0:
		data.last_progress_pos = feet_pos

	data.repath_timer -= delta
	var player_moved_sq := player_pos.distance_squared_to(data.last_repath_player_pos)
	var needs_repath := (
		data.path.is_empty()
		or data.path_index >= data.path.size()
		or data.repath_timer <= 0.0
		or player_moved_sq > PLAYER_REPATH_MOVE_SQ
	)
	if needs_repath:
		_try_repath(feet_pos, goal, data, grid, astar)
		data.last_repath_player_pos = player_pos
		data.repath_timer = REPATH_INTERVAL

	var result := feet_pos
	if data.path_index < data.path.size():
		var target: Vector2 = data.path[data.path_index]
		result = _move_toward(feet_pos, target, grid, collider, delta)
		if result.distance_squared_to(target) < WAYPOINT_REACH_DIST_SQ:
			data.path_index += 1
	else:
		result = _move_toward(feet_pos, goal, grid, collider, delta)

	var still_chasing := result.distance_squared_to(goal) > WAYPOINT_REACH_DIST_SQ
	if _track_stuck(data, result, delta, still_chasing):
		data.clear_path()
		data.stuck_timer = 0.0
		return teleport_beside_player(player_pos, player_velocity, grid, collider, slot)

	if _overlaps_player(result, player_pos, collider):
		if player_idle:
			data.clear_path()
			data.stuck_timer = 0.0
			return teleport_beside_player(player_pos, player_velocity, grid, collider, slot)
		return feet_pos

	return result


## A* goal — player position with velocity lead and per-slot spread (2D prototype feel).
static func _path_goal(
	player_pos: Vector2,
	player_velocity: Vector2,
	data: CompanionData,
) -> Vector2:
	var goal := player_pos
	if player_velocity.length_squared() > 0.01:
		var vel_dir := player_velocity.normalized()
		goal += player_velocity * Config.COMPANION_PREDICT_SECONDS
		var perp := Vector2(-vel_dir.y, vel_dir.x)
		goal += perp * data.slot_lateral_offset
	else:
		goal += data.idle_ring_offset
	return goal


static func spawn_beside_player(
	player_pos: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	slot: int = 0,
	player_velocity: Vector2 = Vector2.ZERO,
) -> Vector2:
	var angle := float(slot) * 1.2
	var preferred := player_pos + Vector2(cos(angle), sin(angle)) * 1.2
	var preferred_dir := Vector2.ZERO
	if player_velocity.length_squared() > 0.01:
		preferred_dir = -player_velocity.normalized()
	return find_clear_pos_near(grid, preferred, collider, slot, false, preferred_dir)


static func find_clear_pos_near(
	grid: CollisionGrid,
	near: Vector2,
	collider: Rect2,
	slot: int,
	include_origin: bool,
	preferred_dir: Vector2 = Vector2.ZERO,
) -> Vector2:
	if include_origin and not grid.entity_blocked(near.x, near.y, collider):
		return near

	var slot_skew := float(slot) * 0.2
	var offsets: Array[Vector2i] = [
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]
	if preferred_dir.length_squared() > 0.01:
		offsets.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var dir := preferred_dir.normalized()
			var dot_a := Vector2(float(a.x), float(a.y)).dot(dir)
			var dot_b := Vector2(float(b.x), float(b.y)).dot(dir)
			return dot_a > dot_b
		)

	for dist in [1.0, 1.4, 2.0, 2.8]:
		for offset in offsets:
			var candidate := Vector2(
				near.x + float(offset.x) * dist - slot_skew,
				near.y + float(offset.y) * dist,
			)
			if not grid.entity_blocked(candidate.x, candidate.y, collider):
				return candidate

	return near


static func teleport_beside_player(
	player_pos: Vector2,
	player_velocity: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	slot: int,
) -> Vector2:
	return spawn_beside_player(player_pos, grid, collider, slot, player_velocity)


static func _try_repath(
	feet_pos: Vector2,
	goal_pos: Vector2,
	data: CompanionData,
	grid: CollisionGrid,
	astar: AStarGrid2D,
) -> void:
	var path := GridPathfinding.find_path(astar, grid, feet_pos, goal_pos)
	if path.is_empty():
		data.clear_path()
		return
	data.path = path
	data.path_index = 0


static func _move_toward(
	feet_pos: Vector2,
	target: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	delta: float,
) -> Vector2:
	var to_target := target - feet_pos
	if to_target.length_squared() < WAYPOINT_REACH_DIST_SQ:
		return feet_pos
	var velocity := to_target.normalized() * SPEED
	return Movement.apply_velocity(grid, feet_pos, velocity, collider, delta)


static func _track_stuck(
	data: CompanionData,
	current_pos: Vector2,
	delta: float,
	still_chasing: bool,
) -> bool:
	if not still_chasing:
		data.stuck_timer = 0.0
		data.last_progress_pos = current_pos
		return false
	if current_pos.distance_squared_to(data.last_progress_pos) >= STUCK_MOVE_EPS_SQ:
		data.stuck_timer = 0.0
		data.last_progress_pos = current_pos
		return false
	data.stuck_timer += delta
	return data.stuck_timer >= STUCK_SECONDS


static func _overlaps_player(
	companion_pos: Vector2,
	player_pos: Vector2,
	companion_collider: Rect2,
) -> bool:
	var player_rect := PlayerCollider.feet_rect()
	player_rect.position += player_pos
	var comp_rect := companion_collider
	comp_rect.position += companion_pos
	return player_rect.intersects(comp_rect)
