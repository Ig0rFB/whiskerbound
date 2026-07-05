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
var player: CharacterBody3D = null
var collision_grid: CollisionGrid = null
var show_collision_debug: bool = false
var quest_flags: Dictionary = {}
