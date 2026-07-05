extends Node
## Entry point — delegates area loading to AreaLoader (M5 prep).

const AreaLoaderScript := preload("res://scenes/area_loader.gd")

@onready var _world_root: Node3D = $WorldRoot

var _loader: RefCounted


func _ready() -> void:
	_loader = AreaLoaderScript.new()
	_loader.bind_world_root(_world_root)

	Events.collision_debug_toggled.connect(_on_collision_debug_toggled)
	Events.debug_restart_requested.connect(_on_debug_restart)
	Events.debug_reload_area_requested.connect(_on_debug_reload_area)
	Events.debug_spawn_companion_requested.connect(_on_debug_spawn_companion)

	_loader.load_fresh("village_green")


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
