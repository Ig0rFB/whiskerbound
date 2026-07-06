extends SceneTree
## Headless check — TPC test map loads and finds the player CharacterBody3D.

const SANDBOX_SCENE := "res://scenes/tools/tpc_sandbox.tscn"


func _initialize() -> void:
	var err := change_scene_to_file(SANDBOX_SCENE)
	if err != OK:
		push_error("TPC_TEST_FAIL: could not load sandbox scene (%s)" % err)
		quit(1)
		return
	call_deferred("_verify")


func _verify() -> void:
	await process_frame
	await process_frame

	var root := current_scene
	if root == null:
		push_error("TPC_TEST_FAIL: no current scene")
		quit(1)
		return

	var player := _find_player_character(root)
	if player == null:
		push_error("TPC_TEST_FAIL: PlayerCharacter not found in sandbox")
		quit(1)
		return

	print(
		"TPC_TEST_OK: sandbox loaded, player at ",
		player.global_position,
	)
	quit(0)


func _find_player_character(root: Node) -> CharacterBody3D:
	for node in root.find_children("*", "CharacterBody3D", true, false):
		if node.name == "PlayerCharacter":
			return node as CharacterBody3D
	return null
