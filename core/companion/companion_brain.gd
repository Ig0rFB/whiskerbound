class_name CompanionBrain
## Companion autonomy: follow always wins; when the player is settled nearby the cat roams, circles,
## sits, or grooms, and meows on its own timer (PROJECT.md §9.2, docs/companion-brain.md).
##
## Pure logic — no Node, no scene lookups. The motor (companion.gd) applies target_feet / hold and
## emits the bark. Behaviour is chosen from companion-owned timers and distance, never player state
## machine flags (the coupling that broke the earlier attempt — see docs/archive/companion-brain-research.md §1).

## Squared distance at which a wander target counts as reached (~0.4 m).
const REACH_DIST_SQ := 0.16


## Fills and returns [param step] (reused across frames to avoid per-frame allocation — AGENTS.md).
static func evaluate(
	feet: Vector2,
	player_feet: Vector2,
	player_moving: bool,
	formation_target: Vector2,
	home_dir: Vector2,
	data: CompanionData,
	delta: float,
	step: CompanionBrainStep,
) -> CompanionBrainStep:
	step.bark_text = ""
	step.hold = false
	step.following = true
	step.activity = CompanionActivity.Type.NONE
	step.target_feet = feet
	_tick_meow(data, delta, step)

	# Tier 1 — follow / catch-up wins whenever the player moves or the cat has strayed too far.
	if player_moving or feet.distance_to(player_feet) > Config.COMPANION_LEASH_SOFT:
		data.activity = CompanionActivity.Type.NONE
		data.activity_timer = 0.0
		data.wander_target = Vector2.ZERO
		step.following = true
		step.hold = false
		step.target_feet = formation_target
		step.activity = CompanionActivity.Type.NONE
		return step

	# Tier 2 — settled near an idle player: run the roam / idle state machine.
	step.following = false
	_tick_activity(data, delta, player_feet, home_dir)

	match data.activity:
		CompanionActivity.Type.WANDER:
			step.target_feet = data.wander_target
			step.hold = feet.distance_squared_to(data.wander_target) <= REACH_DIST_SQ
		CompanionActivity.Type.CIRCLE:
			data.orbit_angle += Config.COMPANION_CIRCLE_SPEED * delta
			step.target_feet = player_feet + Vector2(
				cos(data.orbit_angle), sin(data.orbit_angle)) * Config.COMPANION_CIRCLE_RADIUS
			step.hold = false
		_:
			# SIT / PLAY / GROOM — settle at the formation slot behind the player and rest there,
			# so multiple idle cats fan out instead of clustering where they happened to stop.
			step.target_feet = formation_target
			step.hold = feet.distance_squared_to(formation_target) <= REACH_DIST_SQ

	step.activity = data.activity
	return step


static func _tick_meow(data: CompanionData, delta: float, step: CompanionBrainStep) -> void:
	if data.meow_cooldown > 0.0:
		data.meow_cooldown -= delta
		return
	data.meow_cooldown = randf_range(
		Config.COMPANION_MEOW_MIN_INTERVAL, Config.COMPANION_MEOW_MAX_INTERVAL)
	step.bark_text = CompanionBarkLines.random_line()


static func _tick_activity(
	data: CompanionData, delta: float, player_feet: Vector2, home_dir: Vector2) -> void:
	data.activity_timer -= delta
	if data.activity != CompanionActivity.Type.NONE and data.activity_timer > 0.0:
		return
	_pick_activity(data, player_feet, home_dir)
	data.activity_timer = randf_range(
		Config.COMPANION_ACTIVITY_MIN_SECONDS, Config.COMPANION_ACTIVITY_MAX_SECONDS)


## Weighted random next activity — wander is most common, then circle, then rest in place.
## Wander targets stay within the cat's home sector so multiple cats roam in different directions.
static func _pick_activity(data: CompanionData, player_feet: Vector2, home_dir: Vector2) -> void:
	var base_angle := home_dir.angle() if home_dir.length_squared() > 0.0001 else randf() * TAU
	var roll := randi() % 6
	match roll:
		0, 1, 2:
			data.activity = CompanionActivity.Type.WANDER
			var angle := base_angle + randf_range(
				-Config.COMPANION_WANDER_SECTOR, Config.COMPANION_WANDER_SECTOR)
			var dist := randf_range(0.8, Config.COMPANION_WANDER_RADIUS)
			data.wander_target = player_feet + Vector2(cos(angle), sin(angle)) * dist
		3:
			data.activity = CompanionActivity.Type.CIRCLE
			data.orbit_angle = base_angle
		4:
			data.activity = CompanionActivity.Type.SIT
		_:
			data.activity = CompanionActivity.Type.GROOM
