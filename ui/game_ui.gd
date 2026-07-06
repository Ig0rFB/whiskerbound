extends CanvasLayer
## Gameplay and dialogue UI orchestration (PROJECT.md §12).

@onready var _dialogue_box: Control = $DialogueBox
@onready var _interact_prompt: Control = $InteractPrompt
@onready var _minimap: Control = $Minimap
@onready var _debug_hud: Control = $DebugHud
@onready var _pause_menu: Control = $PauseMenu


func _ready() -> void:
	_pause_menu.resume_requested.connect(_on_pause_resume)
	_pause_menu.quit_requested.connect(_on_pause_quit)
	_pause_menu.save_game_requested.connect(_on_pause_save_game)
	_pause_menu.load_game_requested.connect(_on_pause_load_game)
	GameSettings.settings_changed.connect(_layout_minimap)
	Events.interact_target_changed.connect(_on_interact_target_changed)
	Events.interactable_triggered.connect(_on_interactable_triggered)
	_layout_minimap()
	_interact_prompt.set_show_prompt(false)


func _physics_process(_delta: float) -> void:
	_handle_pause_input()
	if GameState.mode == GameState.GameMode.PAUSE:
		return

	_handle_global_toggles()
	_handle_debug_shortcuts()

	match GameState.mode:
		GameState.GameMode.DIALOGUE:
			if InputActions.interact_pressed:
				_advance_dialogue()


func _handle_pause_input() -> void:
	if GameState.mode == GameState.GameMode.PAUSE:
		_pause_menu.process_gamepad()
		if InputActions.pause_pressed or InputActions.back_pressed:
			if _pause_menu.handle_back():
				return
			_close_pause()
		return

	if InputActions.pause_pressed and GameState.mode == GameState.GameMode.GAMEPLAY:
		_open_pause()


func _handle_global_toggles() -> void:
	if InputActions.toggle_minimap_pressed:
		GameState.show_minimap = not GameState.show_minimap

	if InputActions.toggle_debug_hud_pressed:
		GameState.show_debug_hud = not GameState.show_debug_hud
		GameState.show_collision_debug = GameState.show_debug_hud
		Events.collision_debug_toggled.emit(GameState.show_collision_debug)


func _handle_debug_shortcuts() -> void:
	if not GameState.show_debug_hud or GameState.mode != GameState.GameMode.GAMEPLAY:
		return

	if InputActions.debug_restart_pressed:
		Events.debug_restart_requested.emit()
	if InputActions.debug_spawn_companion_pressed:
		Events.debug_spawn_companion_requested.emit()
	if InputActions.debug_reload_area_pressed:
		Events.debug_reload_area_requested.emit()


func _layout_minimap() -> void:
	var panel_size := GameSettings.minimap_panel_size
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.offset_left = -(panel_size + Config.MINIMAP_MARGIN + 4)
	_minimap.offset_top = Config.MINIMAP_MARGIN
	_minimap.offset_right = -Config.MINIMAP_MARGIN
	_minimap.offset_bottom = Config.MINIMAP_MARGIN + panel_size + 4


func _open_pause() -> void:
	GameState.mode = GameState.GameMode.PAUSE
	_set_player_camera_input(false)
	_pause_menu.open()
	_interact_prompt.set_show_prompt(false)


func _close_pause() -> void:
	GameState.mode = GameState.GameMode.GAMEPLAY
	_pause_menu.close()
	_set_player_camera_input(true)


func _on_pause_resume() -> void:
	_close_pause()


func _on_pause_quit() -> void:
	get_tree().quit()


func _on_pause_save_game() -> void:
	var ok := SaveGame.write_save()
	if ok:
		_pause_menu.set_status_message("Game saved.")
	else:
		_pause_menu.set_status_message("Save failed.")


func _on_pause_load_game() -> void:
	if not SaveGame.has_save():
		_pause_menu.set_status_message("No save file found.")
		return

	var main := get_tree().current_scene
	if main == null or not main.has_method("load_saved_game"):
		_pause_menu.set_status_message("Load failed.")
		return

	if main.load_saved_game():
		_close_pause()
		_pause_menu.set_status_message("Game loaded.")
	else:
		_pause_menu.set_status_message("Load failed.")


func _on_interact_target_changed(target_name: String) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		_interact_prompt.set_show_prompt(false)
		return
	_interact_prompt.set_show_prompt(not target_name.is_empty())


func _on_interactable_triggered(owner: Node) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		return
	if owner == null or not is_instance_valid(owner):
		return
	if not owner.is_in_group("npcs"):
		return
	_begin_dialogue(owner as Node3D)


func _begin_dialogue(npc: Node3D) -> void:
	_set_player_camera_input(false)
	var dialogue_id: int = _resolve_dialogue_id(npc)
	if dialogue_id < 0 or DialogueData.line_count(dialogue_id) == 0:
		return

	GameState.mode = GameState.GameMode.DIALOGUE
	GameState.dialogue_npc = npc
	GameState.dialogue_id = dialogue_id
	GameState.dialogue_line = 0
	_interact_prompt.set_show_prompt(false)

	if GameState.player != null and GameState.player.has_method("face_toward_world"):
		GameState.player.face_toward_world(
			Vector2(npc.global_position.x, npc.global_position.z),
		)

	Events.dialogue_started.emit(dialogue_id)
	_show_current_line()


func _advance_dialogue() -> void:
	var dialogue_id: int = GameState.dialogue_id
	var next_line: int = GameState.dialogue_line + 1
	if next_line >= DialogueData.line_count(dialogue_id):
		_end_dialogue()
		return
	GameState.dialogue_line = next_line
	_show_current_line()


func _show_current_line() -> void:
	var dialogue_id: int = GameState.dialogue_id
	var line_index: int = GameState.dialogue_line
	var speaker := DialogueData.speaker_name(dialogue_id)
	if GameState.dialogue_npc != null:
		speaker = GameState.dialogue_npc.display_name
	var line_text := DialogueData.get_line(dialogue_id, line_index)
	var is_last := line_index >= DialogueData.line_count(dialogue_id) - 1
	_dialogue_box.show_dialogue(speaker, line_text, is_last)


func _end_dialogue() -> void:
	GameState.mode = GameState.GameMode.GAMEPLAY
	GameState.dialogue_npc = null
	GameState.dialogue_id = -1
	GameState.dialogue_line = 0
	_dialogue_box.hide_dialogue()
	Events.dialogue_ended.emit()
	_set_player_camera_input(true)


func _resolve_dialogue_id(npc: Node) -> int:
	var raw_id: Variant = npc.get("dialogue_id")
	var dialogue_id: int = int(raw_id) if raw_id != null else -1
	if dialogue_id < 0:
		var npc_id: Variant = npc.get("npc_id")
		if npc_id != null and str(npc_id) != "":
			dialogue_id = DialogueData.dialogue_id_for_npc(str(npc_id))
	return dialogue_id


func _set_player_camera_input(enabled: bool) -> void:
	var player: CharacterBody3D = GameState.player
	if player == null or not is_instance_valid(player):
		return
	if enabled:
		if player.has_method("capture_camera_mouse"):
			player.capture_camera_mouse()
		if player.has_method("set_camera_input_enabled"):
			player.set_camera_input_enabled(true)
	else:
		if player.has_method("release_camera_mouse"):
			player.release_camera_mouse()
		if player.has_method("set_camera_input_enabled"):
			player.set_camera_input_enabled(false)
