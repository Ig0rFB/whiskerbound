extends Node3D
## Default starter level — map, player, companions, and NPCs in one editor scene.

const GRID_WIDTH := 112
const GRID_HEIGHT := 112
## Dev marker cell — used by smoke tests for a known solid tile.
const MARKER_SOLID_CELL := Vector2i(60, 40)

var _collision_grid: CollisionGrid


func _ready() -> void:
	_collision_grid = _build_collision_grid()


func get_player_spawn_global() -> Vector3:
	var scene_player := get_scene_player()
	if scene_player != null:
		return scene_player.global_position
	return global_position


func get_scene_player() -> TpcPlayer:
	return get_node_or_null("Actors/Player") as TpcPlayer


func get_scene_companions() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if not has_node("Actors/Companions"):
		return result
	for child in $Actors/Companions.get_children():
		if child is Node3D:
			result.append(child as Node3D)
	return result


func get_collision_grid() -> CollisionGrid:
	return _collision_grid


func get_npcs() -> Array:
	var result: Array = []
	if has_node("NPCs"):
		for child in $NPCs.get_children():
			result.append(child)
	return result


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
