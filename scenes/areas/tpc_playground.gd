extends Node3D
## Jeheno third-person playground — sandbox CSG environment with Whiskerbound systems.

const TEST_MAP_SCENE := preload(
	"res://addons/JehenoThirdPersonController/Map/test_map_scene.tscn"
)

const GRID_WIDTH := 112
const GRID_HEIGHT := 112
## Shifts sandbox geometry into positive grid coordinates for collision/minimap.
const WORLD_OFFSET := Vector3(56.0, 0.0, 56.0)
## Dev marker cell — used by smoke tests for a known solid tile.
const MARKER_SOLID_CELL := Vector2i(60, 40)

@onready var _world_offset: Node3D = $WorldOffset

var _collision_grid: CollisionGrid


func _ready() -> void:
	_collision_grid = _build_collision_grid()
	_spawn_environment()


func get_player_spawn_global() -> Vector3:
	return $PlayerSpawn.global_position


func get_collision_grid() -> CollisionGrid:
	return _collision_grid


func get_npcs() -> Array:
	var result: Array = []
	if has_node("NPCs"):
		for child in $NPCs.get_children():
			result.append(child)
	return result


func _spawn_environment() -> void:
	var environment: Node3D = TEST_MAP_SCENE.instantiate()
	_world_offset.add_child(environment)

	var embedded_player := environment.get_node_or_null("PlayerCharacter")
	if embedded_player != null:
		embedded_player.queue_free()


func _build_collision_grid() -> CollisionGrid:
	var grid := CollisionGrid.new()
	grid.configure(GRID_WIDTH, GRID_HEIGHT, Config.GRID_CELL)

	for x in GRID_WIDTH:
		for z in GRID_HEIGHT:
			var border := x <= 1 or z <= 1 or x >= GRID_WIDTH - 2 or z >= GRID_HEIGHT - 2
			if border:
				grid.set_solid(x, z, true)

	grid.set_solid(MARKER_SOLID_CELL.x, MARKER_SOLID_CELL.y, true)
	return grid
