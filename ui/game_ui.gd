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
	_layout_minimap()


func _physics_process(_delta: float) -> void:
	_handle_pause_input()
	if GameState.mode == GameState.GameMode.PAUSE:
		return

	_handle_global_toggles()
	_handle_debug_shortcuts()

	match GameState.mode:
		GameState.GameMode.GAMEPLAY:
			_update_interact_prompt()
			if InputActions.interact_pressed:
				_try_begin_dialogue()
		GameState.GameMode.DIALOGUE:
			_interact_prompt.set_show_prompt(false)
			if InputActions.interact_pressed:
				_advance_dialogue()


func _handle_pause_input() -> void:
	if GameState.mode == GameState.GameMode.PAUSE:
		if InputActions.pause_pressed or InputActions.interact_pressed:
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
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.offset_left = -(Config.MINIMAP_PANEL_SIZE + Config.MINIMAP_MARGIN + 4)
	_minimap.offset_top = Config.MINIMAP_MARGIN
	_minimap.offset_right = -Config.MINIMAP_MARGIN
	_minimap.offset_bottom = Config.MINIMAP_MARGIN + Config.MINIMAP_PANEL_SIZE + 4


func _open_pause() -> void:
	GameState.mode = GameState.GameMode.PAUSE
	_pause_menu.open()
	_interact_prompt.set_show_prompt(false)


func _close_pause() -> void:
	GameState.mode = GameState.GameMode.GAMEPLAY
	_pause_menu.close()


func _on_pause_resume() -> void:
	_close_pause()


func _on_pause_quit() -> void:
	get_tree().quit()


func _update_interact_prompt() -> void:
	var player: CharacterBody3D = GameState.player
	if player == null:
		_interact_prompt.set_show_prompt(false)
		return
	var feet := Vector2(player.global_position.x, player.global_position.z)
	var near := InteractionLogic.player_near_npc(feet, GameState.npcs)
	_interact_prompt.set_show_prompt(near)


func _try_begin_dialogue() -> void:
	var player: CharacterBody3D = GameState.player
	if player == null:
		return
	var feet := Vector2(player.global_position.x, player.global_position.z)
	var npc: Node3D = InteractionLogic.find_nearest_npc(feet, GameState.npcs)
	if npc == null:
		return
	_begin_dialogue(npc)


func _begin_dialogue(npc: Node3D) -> void:
	var dialogue_id: int = npc.dialogue_id
	if dialogue_id < 0 or DialogueData.line_count(dialogue_id) == 0:
		return

	GameState.mode = GameState.GameMode.DIALOGUE
	GameState.dialogue_npc = npc
	GameState.dialogue_id = dialogue_id
	GameState.dialogue_line = 0

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
