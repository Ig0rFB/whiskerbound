extends SceneTree
## Headless companion behaviour assertions: navmesh follow + autonomous brain (PROJECT.md §9.2).
## Run: bash scripts/run_companion_behaviour_test.sh

const NAV_SETTLE_FRAMES := 30
const FOLLOW_FRAMES := 240
const ROAM_FRAMES := 600
## Player walked onto a spot that stays on the spawn platform (x 44..58, z 32..44).
const FOLLOW_TARGET := Vector3(54.0, 0.0, 41.5)
const PLATFORM_MIN_Y := 5.0
const FOLLOW_MAX_END_DIST := 3.5
const ROAM_MIN_DISPLACEMENT := 0.8
const ROAM_MAX_PLAYER_DIST := 5.0

var _failed := false
var _barks := 0


func _initialize() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in NAV_SETTLE_FRAMES:
		await physics_frame

	var gs: Node = root.get_node("GameState")
	var events: Node = root.get_node("Events")
	var player: CharacterBody3D = gs.player
	var companion: CharacterBody3D = gs.companion
	if player == null or companion == null:
		_fail("player or companion is null")
		_finish()
		return
	events.companion_barked.connect(func(_c, _t): _barks += 1)

	_check_navmesh()
	await _check_follow(player, companion)
	await _check_roam(player, companion)
	await _check_fall_recovery(player, companion)
	_finish()


func _check_navmesh() -> void:
	var region := _find_region(root)
	if region == null or region.navigation_mesh == null:
		_fail("no NavigationRegion3D / navmesh")
		return
	if region.navigation_mesh.get_polygon_count() <= 0:
		_fail("navmesh has no polygons")


## Move the player onto the platform; the companion should close in and stay on the platform.
func _check_follow(player: CharacterBody3D, companion: CharacterBody3D) -> void:
	player.global_position = Vector3(FOLLOW_TARGET.x, player.global_position.y, FOLLOW_TARGET.z)
	var target := Vector2(player.global_position.x, player.global_position.z)
	var d_start := _feet(companion).distance_to(target)
	var min_y := INF
	for i in FOLLOW_FRAMES:
		await physics_frame
		min_y = minf(min_y, companion.global_position.y)
	var d_end := _feet(companion).distance_to(target)

	print("BEHAVIOUR: follow d_start=%.2f d_end=%.2f min_y=%.2f" % [d_start, d_end, min_y])
	if d_end >= d_start or d_end > FOLLOW_MAX_END_DIST:
		_fail("companion did not close follow distance (%.2f -> %.2f)" % [d_start, d_end])
	if min_y < PLATFORM_MIN_Y:
		_fail("companion fell off the platform while following (min_y %.2f)" % min_y)


## With the player idle, the companion should roam (move around), stay near, and meow. The activity
## roll is random (it may legitimately rest), so force a WANDER to exercise roam locomotion.
func _check_roam(player: CharacterBody3D, companion: CharacterBody3D) -> void:
	companion._data.meow_cooldown = 0.3
	companion._data.activity = CompanionActivity.Type.WANDER
	companion._data.wander_target = Vector2(
		player.global_position.x + 2.0, player.global_position.z + 2.0)
	companion._data.activity_timer = 20.0
	var start := _feet(companion)
	var target := Vector2(player.global_position.x, player.global_position.z)
	var max_disp := 0.0
	var max_dist := 0.0
	var min_y := INF
	for i in ROAM_FRAMES:
		player.velocity = Vector3.ZERO
		await physics_frame
		max_disp = maxf(max_disp, _feet(companion).distance_to(start))
		max_dist = maxf(max_dist, _feet(companion).distance_to(target))
		min_y = minf(min_y, companion.global_position.y)

	print("BEHAVIOUR: roam barks=%d max_disp=%.2f max_dist=%.2f min_y=%.2f" % [
		_barks, max_disp, max_dist, min_y])
	if _barks < 1:
		_fail("companion never meowed")
	if max_disp < ROAM_MIN_DISPLACEMENT:
		_fail("companion did not roam (max displacement %.2f)" % max_disp)
	if max_dist > ROAM_MAX_PLAYER_DIST:
		_fail("companion wandered too far from the player (%.2f)" % max_dist)
	if min_y < PLATFORM_MIN_Y:
		_fail("companion fell off the platform while roaming (min_y %.2f)" % min_y)


## A companion dropped onto the lower (disconnected) level should snap back beside the player.
func _check_fall_recovery(player: CharacterBody3D, companion: CharacterBody3D) -> void:
	player.global_position = Vector3(54.0, player.global_position.y, 41.5)
	companion.global_position = Vector3(54.0, 0.5, 60.0)
	var recovered := false
	for i in FOLLOW_FRAMES:
		player.velocity = Vector3.ZERO
		await physics_frame
		if companion.global_position.y > PLATFORM_MIN_Y:
			recovered = true
			break

	print("BEHAVIOUR: fall_recovery recovered=%s end_y=%.2f" % [recovered, companion.global_position.y])
	if not recovered:
		_fail("companion did not recover after falling to a lower level")


func _feet(node: Node3D) -> Vector2:
	return Vector2(node.global_position.x, node.global_position.z)


func _find_region(n: Node) -> NavigationRegion3D:
	if n is NavigationRegion3D:
		return n as NavigationRegion3D
	for c in n.get_children():
		var r := _find_region(c)
		if r != null:
			return r
	return null


func _fail(message: String) -> void:
	push_error(message)
	_failed = true


func _finish() -> void:
	if not _failed:
		print("COMPANION_BEHAVIOUR_OK")
	quit(1 if _failed else 0)
