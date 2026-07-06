extends Node
## Serialises gameplay state to user:// for save / load from the pause menu.

const CameraDebugInfoScript := preload("res://core/camera/camera_debug_info.gd")

const SAVE_PATH := "user://savegame.json"
const VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func write_save() -> bool:
	var snapshot := _build_snapshot()
	var json := JSON.stringify(snapshot, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame: could not open %s for writing" % SAVE_PATH)
		return false
	file.store_string(json)
	return true


func read_save() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveGame: could not open %s for reading" % SAVE_PATH)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveGame: invalid save file")
		return {}
	return parsed


func _build_snapshot() -> Dictionary:
	var snapshot := {
		"version": VERSION,
		"area_id": GameState.current_area_id,
		"quest_flags": GameState.quest_flags.duplicate(),
		"companions": [],
	}

	var player: CharacterBody3D = GameState.player
	if player != null:
		snapshot["player_x"] = player.global_position.x
		snapshot["player_z"] = player.global_position.z

	var camera_rig: Node3D = GameState.camera_rig
	if camera_rig != null:
		snapshot["camera_distance"] = CameraDebugInfoScript.get_distance(camera_rig)

	for companion in GameState.companions:
		if companion == null or not is_instance_valid(companion):
			continue
		snapshot["companions"].append({
			"x": companion.global_position.x,
			"z": companion.global_position.z,
		})

	return snapshot
