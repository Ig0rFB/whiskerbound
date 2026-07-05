extends Node
## Entry point — loads the active area, spawns the player, attaches the camera rig.

const AREA_SCENES := {
	"village_green": "res://scenes/areas/village_green.tscn",
}

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CAMERA_RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")

@onready var _world_root: Node3D = $WorldRoot

var _area: Node3D
var _player: CharacterBody3D
var _camera_rig: Node3D


func _ready() -> void:
	_load_area("village_green")


func _load_area(area_id: String) -> void:
	if not AREA_SCENES.has(area_id):
		push_error("Unknown area: %s" % area_id)
		return

	if _area:
		_area.queue_free()
		_area = null
	if _player:
		_player.queue_free()
		_player = null
	if _camera_rig:
		_camera_rig.queue_free()
		_camera_rig = null

	var area_scene: PackedScene = load(AREA_SCENES[area_id])
	_area = area_scene.instantiate()
	_world_root.add_child(_area)

	_player = PLAYER_SCENE.instantiate()
	_world_root.add_child(_player)

	var spawn_pos: Vector3 = _area.get_player_spawn_global()
	_player.global_position = spawn_pos

	_camera_rig = CAMERA_RIG_SCENE.instantiate()
	_world_root.add_child(_camera_rig)
	_camera_rig.set_target(_player, true)

	GameState.current_area_id = area_id
	GameState.player = _player
	Events.area_entered.emit(area_id)
