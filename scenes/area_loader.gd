extends RefCounted
## Loads and swaps area scenes — fresh boot vs transition (M5 prep).

const AREA_SCENES := {
	"tpc_playground": "res://scenes/areas/tpc_playground.tscn",
	"village_green": "res://scenes/areas/village_green.tscn",
}

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const COMPANION_SCENE := preload("res://scenes/companion/companion.tscn")
const COLLISION_DEBUG_SCENE := preload("res://scenes/debug/collision_debug.tscn")
const COMPANION_PATH_DEBUG_SCENE := preload("res://scenes/debug/companion_path_debug.tscn")

var area: Node3D = null
var player: CharacterBody3D = null
var companions: Array[Node3D] = []
var collision_debug: Node3D = null
var companion_path_debug: Node3D = null

var _world_root: Node3D = null


func bind_world_root(world_root: Node3D) -> void:
	_world_root = world_root


func load_fresh(area_id: String) -> void:
	clear_all()
	_load_area_scene(area_id)
	_spawn_player(_area_spawn_position(area, ""))
	_spawn_initial_companion()
	_spawn_collision_debug()
	_spawn_companion_path_debug()
	_sync_game_state(area_id)


func load_from_save(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false

	var area_id: String = str(snapshot.get("area_id", "tpc_playground"))
	if not AREA_SCENES.has(area_id):
		push_error("SaveGame: unknown area %s" % area_id)
		return false

	clear_all()
	_load_area_scene(area_id)

	var player_x := float(snapshot.get("player_x", 0.0))
	var player_z := float(snapshot.get("player_z", 0.0))
	_spawn_player(Vector3(player_x, 0.0, player_z))

	var companion_data: Array = snapshot.get("companions", [])
	if companion_data.is_empty():
		_spawn_initial_companion()
	else:
		for slot in companion_data.size():
			var entry: Dictionary = companion_data[slot]
			var feet := Vector2(float(entry.get("x", 0.0)), float(entry.get("z", 0.0)))
			var companion: Node3D = COMPANION_SCENE.instantiate()
			_world_root.add_child(companion)
			companion.setup(slot, feet)
			companions.append(companion)

	if snapshot.has("camera_distance"):
		_apply_saved_camera_distance(float(snapshot["camera_distance"]))

	_spawn_collision_debug()
	_spawn_companion_path_debug()
	GameState.quest_flags = snapshot.get("quest_flags", {}).duplicate()
	_sync_game_state(area_id)
	return true


func reload_current(spawn_name: String = "") -> void:
	if area == null or GameState.current_area_id.is_empty():
		return

	var area_id := GameState.current_area_id
	var kept_player := player
	var kept_companions := companions.duplicate()
	var kept_debug := collision_debug
	var kept_path_debug := companion_path_debug

	player = null
	companions.clear()
	collision_debug = null
	companion_path_debug = null

	_unload_area()
	_load_area_scene(area_id)

	var spawn_pos := _area_spawn_position(area, spawn_name)
	if kept_player != null and is_instance_valid(kept_player):
		player = kept_player
		player.global_position = spawn_pos
	elif player == null:
		_spawn_player(spawn_pos)

	companions = kept_companions
	_reposition_companions()

	if kept_debug != null and is_instance_valid(kept_debug):
		collision_debug = kept_debug
		collision_debug.setup(GameState.collision_grid)
		collision_debug.set_overlay_visible(GameState.show_collision_debug)
	elif collision_debug == null:
		_spawn_collision_debug()

	if kept_path_debug != null and is_instance_valid(kept_path_debug):
		companion_path_debug = kept_path_debug
		companion_path_debug.set_overlay_visible(GameState.show_debug_hud)
	elif companion_path_debug == null:
		_spawn_companion_path_debug()

	_sync_game_state(area_id)


func spawn_debug_companion() -> bool:
	if player == null or GameState.collision_grid == null:
		return false
	if companions.size() >= Config.DEBUG_MAX_COMPANIONS:
		return false

	var slot := companions.size()
	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	var other_feet := _companion_feet_excluding(-1)
	var spawn_feet := CompanionLogic.spawn_beside_player(
		player_feet,
		GameState.collision_grid,
		CompanionCollider.feet_rect(),
		slot,
		Vector2.ZERO,
		other_feet,
	)
	var companion: Node3D = COMPANION_SCENE.instantiate()
	_world_root.add_child(companion)
	companion.setup(slot, spawn_feet)
	companions.append(companion)
	_sync_companion_state()
	return true


func set_collision_debug_visible(show_it: bool) -> void:
	if collision_debug:
		collision_debug.set_overlay_visible(show_it)


func set_companion_path_debug_visible(show_it: bool) -> void:
	if companion_path_debug:
		companion_path_debug.set_overlay_visible(show_it)


func set_debug_overlays_visible(show_it: bool) -> void:
	set_collision_debug_visible(show_it)
	set_companion_path_debug_visible(show_it)


func clear_all() -> void:
	_unload_area()
	_free_entity(player)
	player = null
	for companion in companions:
		_free_entity(companion)
	companions.clear()
	_free_entity(collision_debug)
	collision_debug = null
	_free_entity(companion_path_debug)
	companion_path_debug = null
	_reset_dialogue_state()


func _load_area_scene(area_id: String) -> void:
	if not AREA_SCENES.has(area_id):
		push_error("Unknown area: %s" % area_id)
		return

	var area_scene: PackedScene = load(AREA_SCENES[area_id])
	area = area_scene.instantiate()
	_world_root.add_child(area)

	GameState.collision_grid = area.get_collision_grid()
	GameState.pathfinder = GridPathfinding.build_from_grid(GameState.collision_grid)


func _unload_area() -> void:
	if area:
		area.queue_free()
		area = null
	GameState.pathfinder = null


func _spawn_player(spawn_pos: Vector3) -> void:
	player = PLAYER_SCENE.instantiate()
	_world_root.add_child(player)
	player.global_position = spawn_pos
	if player.has_method("_bind_camera_to_game_state"):
		player.call_deferred("_bind_camera_to_game_state")


func _spawn_initial_companion() -> void:
	if player == null:
		return

	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	var companion_feet := CompanionLogic.spawn_beside_player(
		player_feet,
		GameState.collision_grid,
		CompanionCollider.feet_rect(),
		0,
	)
	var companion: Node3D = COMPANION_SCENE.instantiate()
	_world_root.add_child(companion)
	companion.setup(0, companion_feet)
	companions.append(companion)


func _spawn_collision_debug() -> void:
	collision_debug = COLLISION_DEBUG_SCENE.instantiate()
	_world_root.add_child(collision_debug)
	collision_debug.setup(GameState.collision_grid)
	collision_debug.set_overlay_visible(GameState.show_collision_debug)


func _spawn_companion_path_debug() -> void:
	companion_path_debug = COMPANION_PATH_DEBUG_SCENE.instantiate()
	_world_root.add_child(companion_path_debug)
	companion_path_debug.set_overlay_visible(GameState.show_debug_hud)


func _reposition_companions() -> void:
	if player == null or GameState.collision_grid == null:
		return

	var player_feet := Vector2(player.global_position.x, player.global_position.z)
	for slot in companions.size():
		var companion := companions[slot]
		if not is_instance_valid(companion):
			continue
		var other_feet := _companion_feet_excluding(slot)
		var spawn_feet := CompanionLogic.spawn_beside_player(
			player_feet,
			GameState.collision_grid,
			CompanionCollider.feet_rect(),
			slot,
			Vector2.ZERO,
			other_feet,
		)
		companion.setup(slot, spawn_feet)


func _companion_feet_excluding(exclude_slot: int) -> PackedVector2Array:
	var feet := PackedVector2Array()
	for slot in companions.size():
		if slot == exclude_slot:
			continue
		var companion := companions[slot]
		if companion == null or not is_instance_valid(companion):
			continue
		feet.append(Vector2(companion.global_position.x, companion.global_position.z))
	return feet


func _area_spawn_position(area_node: Node3D, spawn_name: String) -> Vector3:
	if spawn_name.is_empty():
		return area_node.get_player_spawn_global()
	if area_node.has_method("get_named_spawn_global"):
		return area_node.get_named_spawn_global(spawn_name)
	return area_node.get_player_spawn_global()


func _apply_saved_camera_distance(dist: float) -> void:
	if player != null and player.has_method("set_camera_distance"):
		player.set_camera_distance(dist)


func _sync_game_state(area_id: String) -> void:
	GameState.current_area_id = area_id
	GameState.player = player
	GameState.camera_rig = _player_camera_rig()
	GameState.npcs = area.get_npcs() if area else []
	_sync_companion_state()
	Events.area_entered.emit(area_id)


func _player_camera_rig() -> Node3D:
	if player == null:
		return null
	if "cam_holder" in player and player.cam_holder != null:
		return player.cam_holder as Node3D
	return null


func _sync_companion_state() -> void:
	GameState.companions = companions
	GameState.companion = companions[0] if companions.size() > 0 else null


func _reset_dialogue_state() -> void:
	GameState.companion = null
	GameState.companions = []
	GameState.camera_rig = null
	GameState.npcs = []
	GameState.dialogue_npc = null
	GameState.dialogue_id = -1
	GameState.dialogue_line = 0
	GameState.mode = GameState.GameMode.GAMEPLAY


func _free_entity(node: Node) -> void:
	if node:
		node.queue_free()
