extends Node
## Central game state — plain data, no rendering (PROJECT.md §6.2).

enum GameMode {
	GAMEPLAY,
	DIALOGUE,
	PAUSE,
	MENU,
	INVENTORY,
}

var mode: GameMode = GameMode.GAMEPLAY
var current_area_id: String = ""
var player: TpcPlayer = null
var camera_rig: Node3D = null
var collision_grid: CollisionGrid = null
var pathfinder: AStarGrid2D = null
var companion: Node3D = null
var companions: Array[Node3D] = []
var npcs: Array = []
var show_collision_debug: bool = false
var show_debug_hud: bool = false
var show_minimap: bool = true
var dialogue_npc: Node3D = null
var dialogue_id: int = -1
var dialogue_line: int = 0
var quest_flags: Dictionary = {}


func clear_world_refs() -> void:
	player = null
	camera_rig = null
	collision_grid = null
	pathfinder = null
	companion = null
	companions.clear()
	npcs.clear()
	dialogue_npc = null
	dialogue_id = -1
	dialogue_line = 0
	mode = GameMode.GAMEPLAY
