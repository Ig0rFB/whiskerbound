extends CanvasLayer
## Gameplay and dialogue UI orchestration (PROJECT.md §12).

@onready var _dialogue_box: Control = $DialogueBox
@onready var _interact_prompt: Control = $InteractPrompt


func _physics_process(_delta: float) -> void:
	match GameState.mode:
		GameState.GameMode.GAMEPLAY:
			_update_interact_prompt()
			if InputActions.interact_pressed:
				_try_begin_dialogue()
		GameState.GameMode.DIALOGUE:
			_interact_prompt.set_show_prompt(false)
			if InputActions.interact_pressed:
				_advance_dialogue()


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
