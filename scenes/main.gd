extends Node
## Entry point — loads the active area, spawns the player, attaches the camera rig.

const AREA_SCENES := {
	"village_green": "res://scenes/areas/village_green.tscn",
}

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const COMPANION_SCENE := preload("res://scenes/companion/companion.tscn")
const CAMERA_RIG_SCENE := preload("res://scenes/camera/camera_rig.tscn")
const COLLISION_DEBUG_SCENE := preload("res://scenes/debug/collision_debug.tscn")

@onready var _world_root: Node3D = $WorldRoot

var _area: Node3D
var _player: CharacterBody3D
var _companion: Node3D
var _camera_rig: Node3D
var _collision_debug: Node3D


func _ready() -> void:
	_load_area("village_green")


func _physics_process(_delta: float) -> void:
	InputActions.poll()

	if InputActions.toggle_collision_debug_pressed:
		GameState.show_collision_debug = not GameState.show_collision_debug
		if _collision_debug:
			_collision_debug.set_overlay_visible(GameState.show_collision_debug)


func _load_area(area_id: String) -> void:
	if not AREA_SCENES.has(area_id):
		push_error("Unknown area: %s" % area_id)
		return

	_clear_world()

	var area_scene: PackedScene = load(AREA_SCENES[area_id])
	_area = area_scene.instantiate()
	_world_root.add_child(_area)

	GameState.collision_grid = _area.get_collision_grid()
	GameState.pathfinder = GridPathfinding.build_from_grid(GameState.collision_grid)

	_player = PLAYER_SCENE.instantiate()
	_world_root.add_child(_player)

	var spawn_pos: Vector3 = _area.get_player_spawn_global()
	_player.global_position = spawn_pos

	_companion = COMPANION_SCENE.instantiate()
	_world_root.add_child(_companion)
	var player_feet := Vector2(spawn_pos.x, spawn_pos.z)
	var companion_feet := CompanionLogic.spawn_beside_player(
		player_feet,
		GameState.collision_grid,
		CompanionCollider.feet_rect(),
		0,
	)
	_companion.setup(0, companion_feet)

	_camera_rig = CAMERA_RIG_SCENE.instantiate()
	_world_root.add_child(_camera_rig)
	_camera_rig.set_target(_player, true)

	_collision_debug = COLLISION_DEBUG_SCENE.instantiate()
	_world_root.add_child(_collision_debug)
	_collision_debug.setup(GameState.collision_grid)
	_collision_debug.set_overlay_visible(GameState.show_collision_debug)

	GameState.current_area_id = area_id
	GameState.player = _player
	GameState.companion = _companion
	GameState.npcs = _area.get_npcs()
	Events.area_entered.emit(area_id)


func _clear_world() -> void:
	if _area:
		_area.queue_free()
		_area = null
	if _player:
		_player.queue_free()
		_player = null
	if _companion:
		_companion.queue_free()
		_companion = null
	if _camera_rig:
		_camera_rig.queue_free()
		_camera_rig = null
	if _collision_debug:
		_collision_debug.queue_free()
		_collision_debug = null
	GameState.companion = null
	GameState.pathfinder = null
	GameState.npcs = []
	GameState.dialogue_npc = null
	GameState.dialogue_id = -1
	GameState.dialogue_line = 0
	GameState.mode = GameState.GameMode.GAMEPLAY
