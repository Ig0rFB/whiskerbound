class_name CompanionIdleLogic
## Autonomous idle behaviour when the player is still nearby (PROJECT.md §9.2).

const WAYPOINT_REACH_DIST_SQ := 0.08


static func update(
	feet_pos: Vector2,
	player_pos: Vector2,
	data: CompanionData,
	grid: CollisionGrid,
	astar: AStarGrid2D,
	collider: Rect2,
	slot: int,
	delta: float,
	other_feet: PackedVector2Array = PackedVector2Array(),
) -> CompanionIdleStep:
	var step := CompanionIdleStep.new()
	step.feet = feet_pos
	step.activity = data.activity
	step.moving = false
	step.bark_text = ""

	_tick_meow(data, delta, step)
	_tick_activity_timer(data, delta, player_pos, feet_pos, grid, collider, slot, other_feet)

	match data.activity:
		CompanionActivity.Type.WANDER:
			step.feet = _tick_wander(
				feet_pos, data, grid, astar, collider, slot, delta, other_feet,
			)
			step.moving = step.feet.distance_squared_to(feet_pos) > 0.0001
		CompanionActivity.Type.SIT, CompanionActivity.Type.PLAY, CompanionActivity.Type.GROOM:
			step.feet = feet_pos
			step.moving = false
		_:
			step.feet = feet_pos

	step.activity = data.activity
	return step


static func _tick_meow(data: CompanionData, delta: float, step: CompanionIdleStep) -> void:
	if data.meow_cooldown > 0.0:
		data.meow_cooldown -= delta
		return
	data.meow_cooldown = randf_range(
		Config.COMPANION_MEOW_MIN_INTERVAL,
		Config.COMPANION_MEOW_MAX_INTERVAL,
	)
	step.bark_text = CompanionBarkLines.random_line()


static func _tick_activity_timer(
	data: CompanionData,
	delta: float,
	player_pos: Vector2,
	feet_pos: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	slot: int,
	other_feet: PackedVector2Array,
) -> void:
	data.activity_timer -= delta
	if data.activity != CompanionActivity.Type.NONE and data.activity_timer > 0.0:
		return
	_pick_next_activity(data, player_pos, feet_pos, grid, collider, slot, other_feet)
	data.activity_timer = randf_range(
		Config.COMPANION_ACTIVITY_MIN_SECONDS,
		Config.COMPANION_ACTIVITY_MAX_SECONDS,
	)


static func _pick_next_activity(
	data: CompanionData,
	player_pos: Vector2,
	feet_pos: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	slot: int,
	other_feet: PackedVector2Array,
) -> void:
	var roll := randi() % 4
	match roll:
		0:
			data.activity = CompanionActivity.Type.WANDER
			data.wander_target = _pick_wander_target(
				player_pos, feet_pos, grid, collider, slot, other_feet,
			)
		1:
			data.activity = CompanionActivity.Type.SIT
			data.wander_target = Vector2.ZERO
			data.clear_path()
		2:
			data.activity = CompanionActivity.Type.PLAY
			data.wander_target = Vector2.ZERO
			data.clear_path()
		_:
			data.activity = CompanionActivity.Type.GROOM
			data.wander_target = Vector2.ZERO
			data.clear_path()


static func _pick_wander_target(
	player_pos: Vector2,
	feet_pos: Vector2,
	grid: CollisionGrid,
	collider: Rect2,
	slot: int,
	other_feet: PackedVector2Array,
) -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(0.8, Config.COMPANION_WANDER_RADIUS)
	var candidate := player_pos + Vector2(cos(angle), sin(angle)) * dist
	return CompanionLogic.find_clear_pos_near(
		grid, candidate, collider, slot, true, feet_pos - player_pos, other_feet,
	)


static func _tick_wander(
	feet_pos: Vector2,
	data: CompanionData,
	grid: CollisionGrid,
	astar: AStarGrid2D,
	collider: Rect2,
	slot: int,
	delta: float,
	other_feet: PackedVector2Array,
) -> Vector2:
	if data.wander_target == Vector2.ZERO:
		return feet_pos

	if feet_pos.distance_squared_to(data.wander_target) <= WAYPOINT_REACH_DIST_SQ:
		data.wander_target = Vector2.ZERO
		data.clear_path()
		return feet_pos

	data.repath_timer -= delta
	if data.path.is_empty() or data.path_index >= data.path.size() or data.repath_timer <= 0.0:
		var path := GridPathfinding.find_path(astar, grid, feet_pos, data.wander_target)
		if path.is_empty():
			data.wander_target = Vector2.ZERO
			data.clear_path()
			return feet_pos
		data.path = path
		data.path_index = 0
		data.repath_timer = Config.COMPANION_REPATH_INTERVAL

	if data.path_index < data.path.size():
		var target: Vector2 = data.path[data.path_index]
		var result := CompanionLogic.move_toward_feet(
			feet_pos, target, grid, collider, delta, other_feet,
		)
		if result.distance_squared_to(target) < WAYPOINT_REACH_DIST_SQ:
			data.path_index += 1
		return result

	return CompanionLogic.move_toward_feet(
		feet_pos, data.wander_target, grid, collider, delta, other_feet,
	)
