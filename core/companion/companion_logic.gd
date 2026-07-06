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
	other_feet: PackedVector2Array = PackedVector2Array(),
) -> Vector2:
	if grid.center_cell_blocked(feet_pos.x, feet_pos.y):
		data.clear_path()
		data.stuck_timer = 0.0
		return teleport_beside_player(
			player_pos, player_velocity, grid, collider, slot, other_feet,
		)

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
		result = _move_toward(feet_pos, target, grid, collider, delta, other_feet)
		if result.distance_squared_to(target) < WAYPOINT_REACH_DIST_SQ:
			data.path_index += 1
	else:
		result = _move_toward(feet_pos, goal, grid, collider, delta, other_feet)

	var still_chasing := result.distance_squared_to(goal) > WAYPOINT_REACH_DIST_SQ
	if _track_stuck(data, result, delta, still_chasing):
		data.clear_path()
		data.stuck_timer = 0.0
		return teleport_beside_player(
			player_pos, player_velocity, grid, collider, slot, other_feet,
		)

	if _overlaps_player(result, player_pos, collider):
		if player_idle:
			data.clear_path()
			data.stuck_timer = 0.0
			return teleport_beside_player(
				player_pos, player_velocity, grid, collider, slot, other_feet,
			)
		return feet_pos

	return nudge_from_companions(result, collider, slot, other_feet, grid)


## Public wrapper for idle wander steps (core stays grid-pure).
static func move_toward_feet(
	feet_pos: Vector2,
	target: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	delta: float,
	other_feet: PackedVector2Array,
) -> Vector2:
	return _move_toward(feet_pos, target, grid, collider, delta, other_feet)


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
	other_feet: PackedVector2Array = PackedVector2Array(),
) -> Vector2:
	var angle := float(slot) * 1.2
	var preferred := player_pos + Vector2(cos(angle), sin(angle)) * 1.2
	var preferred_dir := Vector2.ZERO
	if player_velocity.length_squared() > 0.01:
		preferred_dir = -player_velocity.normalized()
	return find_clear_pos_near(
		grid, preferred, collider, slot, false, preferred_dir, other_feet,
	)


static func find_clear_pos_near(
	grid: CollisionGrid,
	near: Vector2,
	collider: Rect2,
	slot: int,
	include_origin: bool,
	preferred_dir: Vector2 = Vector2.ZERO,
	other_feet: PackedVector2Array = PackedVector2Array(),
) -> Vector2:
	if include_origin and _is_clear(grid, near, collider, other_feet):
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
			if _is_clear(grid, candidate, collider, other_feet):
				return candidate

	return near


static func teleport_beside_player(
	player_pos: Vector2,
	player_velocity: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	slot: int,
	other_feet: PackedVector2Array = PackedVector2Array(),
) -> Vector2:
	return spawn_beside_player(
		player_pos, grid, collider, slot, player_velocity, other_feet,
	)


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
	other_feet: PackedVector2Array,
) -> Vector2:
	var to_target := target - feet_pos
	if to_target.length_squared() < WAYPOINT_REACH_DIST_SQ:
		return feet_pos
	var velocity := to_target.normalized() * SPEED
	return _apply_companion_velocity(grid, feet_pos, velocity, collider, delta, other_feet)


static func _apply_companion_velocity(
	grid: CollisionGrid,
	feet_pos: Vector2,
	velocity: Vector2,
	collider: Rect2,
	delta: float,
	other_feet: PackedVector2Array,
) -> Vector2:
	var result := feet_pos
	var delta_pos := velocity * delta

	var new_x := result.x + delta_pos.x
	if _is_clear(grid, Vector2(new_x, result.y), collider, other_feet):
		result.x = new_x

	var new_z := result.y + delta_pos.y
	if _is_clear(grid, Vector2(result.x, new_z), collider, other_feet):
		result.y = new_z

	return result


static func _is_clear(
	grid: CollisionGrid,
	feet_pos: Vector2,
	collider: Rect2,
	other_feet: PackedVector2Array,
) -> bool:
	if grid.entity_blocked(feet_pos.x, feet_pos.y, collider):
		return false
	return not blocked_by_companions(feet_pos, collider, other_feet)


static func blocked_by_companions(
	feet_pos: Vector2,
	collider: Rect2,
	other_feet: PackedVector2Array,
) -> bool:
	var other_col := CompanionCollider.feet_rect()
	for other in other_feet:
		if feet_overlap(feet_pos, collider, other, other_col):
			return true
	return false


static func feet_overlap(
	a_pos: Vector2,
	a_col: Rect2,
	b_pos: Vector2,
	b_col: Rect2,
) -> bool:
	var a_rect := a_col
	a_rect.position += a_pos
	var b_rect := b_col
	b_rect.position += b_pos
	return a_rect.intersects(b_rect)


## Push apart when companions stack — keeps core free of GameState references.
static func nudge_from_companions(
	feet_pos: Vector2,
	collider: Rect2,
	slot: int,
	other_feet: PackedVector2Array,
	grid: CollisionGrid,
) -> Vector2:
	var result := feet_pos
	var other_col := CompanionCollider.feet_rect()
	var min_sep := CompanionCollider.FEET_RADIUS * 2.0 + 0.06

	for i in other_feet.size():
		var other := other_feet[i]
		var delta := result - other
		if delta.length_squared() >= min_sep * min_sep:
			continue
		var push_dir := delta
		if push_dir.length_squared() < 0.0001:
			push_dir = Vector2(
				cos(float(slot) * 1.2 + float(i)),
				sin(float(slot) * 1.2 + float(i)),
			)
		result = other + push_dir.normalized() * min_sep

	if grid.entity_blocked(result.x, result.y, collider):
		return feet_pos
	if blocked_by_companions(result, collider, other_feet):
		return feet_pos
	return result


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
