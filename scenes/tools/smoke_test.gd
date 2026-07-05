extends SceneTree
## Headless smoke test — run with: godot --path . --headless scenes/tools/smoke_test.gd

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		push_error("Failed to load main.tscn")
		quit(1)
		return

	var main: Node = main_scene.instantiate()
	root.add_child(main)

	# Allow one frame for area/player/camera setup.
	await process_frame

	var game_state: Node = root.get_node("GameState")
	var player: CharacterBody3D = game_state.player
	if player == null:
		push_error("GameState.player is null after main _ready")
		quit(1)
		return

	if game_state.current_area_id != "village_green":
		push_error("Expected village_green, got: %s" % game_state.current_area_id)
		quit(1)
		return

	print("SMOKE_OK: player at ", player.global_position, " area=", game_state.current_area_id)
	quit(0)
