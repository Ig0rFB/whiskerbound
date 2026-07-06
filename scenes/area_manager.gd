class_name AreaManager
extends Node
## Loads and swaps area scenes — fresh boot vs transition (M5 prep).

const AREA_SCENES := {
	"playground": "res://scenes/areas/playground.tscn",
	"village_green": "res://scenes/areas/village_green.tscn",
}

const LEGACY_AREA_IDS := {
	"tpc_playground": "playground",
}

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const COMPANION_SCENE := preload("res://scenes/companion/companion.tscn")
const COLLISION_DEBUG_SCENE := preload("res://scenes/debug/collision_debug.tscn")
const COMPANION_PATH_DEBUG_SCENE := preload("res://scenes/debug/companion_path_debug.tscn")

var area: Node3D = null
var player: TpcPlayer = null
var companions: Array[Node3D] = []
var collision_debug: Node3D = null
var companion_path_debug: Node3D = null

@onready var _world_root: Node3D = %WorldRoot


func load_fresh(area_id: String) -> void:
	clear_all()
	var resolved_id := _normalize_area_id(area_id)
	_load_area_scene(resolved_id)
	if not _try_adopt_player(area):
		_spawn_player(_area_spawn_position(area, ""))
	if not _try_adopt_companions(area):
		_spawn_initial_companion()
	_spawn_collision_debug()
	_spawn_companion_path_debug()
	_sync_game_state(resolved_id)


func load_from_save(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false

	var area_id := _normalize_area_id(str(snapshot.get("area_id", "playground")))
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
			companion.setup(slot, feet, player.global_position.y + 2.0)
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
	companion.setup(slot, spawn_feet, player.global_position.y + 2.0)
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


func _try_adopt_player(area_node: Node3D) -> bool:
	var scene_player: TpcPlayer = null
	if area_node.has_method("get_scene_player"):
		scene_player = area_node.get_scene_player()
	elif area_node.has_node("Actors/Player"):
		scene_player = area_node.get_node("Actors/Player") as TpcPlayer
	if scene_player == null:
		return false

	player = scene_player
	player.reparent(_world_root)
	if player.has_method("_bind_camera_to_game_state"):
		player.call_deferred("_bind_camera_to_game_state")
	return true


func _try_adopt_companions(area_node: Node3D) -> bool:
	var nodes: Array[Node3D] = []
	if area_node.has_method("get_scene_companions"):
		nodes = area_node.get_scene_companions()
	elif area_node.has_node("Actors/Companions"):
		for child in area_node.get_node("Actors/Companions").get_children():
			if child is Node3D:
				nodes.append(child as Node3D)
	if nodes.is_empty():
		return false

	for slot in nodes.size():
		var companion: Node3D = nodes[slot]
		companion.reparent(_world_root)
		if companion.has_method("activate"):
			companion.activate(slot)
		elif companion.has_method("setup"):
			var feet := Vector2(companion.global_position.x, companion.global_position.z)
			companion.setup(slot, feet, companion.global_position.y)
		companions.append(companion)
	return true


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
	companion.setup(0, companion_feet, player.global_position.y + 2.0)
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
		companion.setup(slot, spawn_feet, player.global_position.y + 2.0)


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


func _normalize_area_id(area_id: String) -> String:
	return LEGACY_AREA_IDS.get(area_id, area_id)


func _free_entity(node: Node) -> void:
	if node:
		node.queue_free()
