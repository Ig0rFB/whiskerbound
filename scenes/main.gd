extends Node
## Entry point — boots UI and delegates area loading to AreaManager.

const TpcInputSetupScript := preload("res://scenes/tools/tpc_input_setup.gd")

@onready var _area_manager: AreaManager = $AreaManager


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	TpcInputSetupScript.ensure_actions_registered()

	Events.collision_debug_toggled.connect(_on_collision_debug_toggled)
	Events.debug_restart_requested.connect(_on_debug_restart)
	Events.debug_reload_area_requested.connect(_on_debug_reload_area)
	Events.debug_spawn_companion_requested.connect(_on_debug_spawn_companion)

	_area_manager.load_fresh("playground")
	_area_manager.set_debug_overlays_visible(GameState.show_debug_hud)


func _on_collision_debug_toggled(show_it: bool) -> void:
	_area_manager.set_debug_overlays_visible(show_it)


func _on_debug_restart() -> void:
	if GameState.current_area_id.is_empty():
		return
	_area_manager.load_fresh(GameState.current_area_id)


func _on_debug_reload_area() -> void:
	_area_manager.reload_current()


func _on_debug_spawn_companion() -> void:
	_area_manager.spawn_debug_companion()


func load_saved_game() -> bool:
	var snapshot := SaveGame.read_save()
	if snapshot.is_empty():
		return false
	return _area_manager.load_from_save(snapshot)
