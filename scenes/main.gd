extends Node
## Entry point — delegates area loading to AreaLoader (M5 prep).

const AreaLoaderScript := preload("res://scenes/area_loader.gd")
const TpcInputSetupScript := preload("res://scenes/tools/tpc_input_setup.gd")

@onready var _world_root: Node3D = $WorldRoot

var _loader: RefCounted


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	TpcInputSetupScript.ensure_actions_registered()
	_loader = AreaLoaderScript.new()
	_loader.bind_world_root(_world_root)

	Events.collision_debug_toggled.connect(_on_collision_debug_toggled)
	Events.debug_restart_requested.connect(_on_debug_restart)
	Events.debug_reload_area_requested.connect(_on_debug_reload_area)
	Events.debug_spawn_companion_requested.connect(_on_debug_spawn_companion)

	_loader.load_fresh("tpc_playground")
	_loader.set_debug_overlays_visible(GameState.show_debug_hud)


func _on_collision_debug_toggled(show_it: bool) -> void:
	_loader.set_debug_overlays_visible(show_it)


func _on_debug_restart() -> void:
	if GameState.current_area_id.is_empty():
		return
	_loader.load_fresh(GameState.current_area_id)


func _on_debug_reload_area() -> void:
	_loader.reload_current()


func _on_debug_spawn_companion() -> void:
	_loader.spawn_debug_companion()


func load_saved_game() -> bool:
	var snapshot := SaveGame.read_save()
	if snapshot.is_empty():
		return false
	return _loader.load_from_save(snapshot)
