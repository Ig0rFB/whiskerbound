extends Node3D
## Default starter level — map, player, companions, and NPCs in one editor scene.

const GRID_WIDTH := 112
const GRID_HEIGHT := 112
## Dev marker cell — used by smoke tests for a known solid tile.
const MARKER_SOLID_CELL := Vector2i(60, 40)

## Walkable source geometry: elevated CSG platforms plus the ground plane.
const NAV_SOURCE_PATHS := [
	"WorldOffset/Structures/CSGCombiner3D",
	"WorldOffset/Structures/Ground/GroundMesh",
]

var _collision_grid: CollisionGrid
var _nav_region: NavigationRegion3D


func _ready() -> void:
	_collision_grid = _build_collision_grid()
	_build_navigation_region()


func get_player_spawn_global() -> Vector3:
	var scene_player := get_scene_player()
	if scene_player != null:
		return scene_player.global_position
	return global_position


func get_scene_player() -> WhiskerboundPlayer:
	return get_node_or_null("Actors/Player") as WhiskerboundPlayer


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


func get_navigation_region() -> NavigationRegion3D:
	return _nav_region


## Attach a NavigationRegion3D so companions path over the CSG tops, not the coarse grid
## (PROJECT.md §4). Ships a pre-baked navmesh resource (regenerate with
## scenes/tools/bake_playground_navmesh.gd); falls back to a runtime bake if it is missing.
func _build_navigation_region() -> void:
	var world_offset := get_node_or_null("WorldOffset") as Node3D
	if world_offset == null:
		push_warning("Playground: no WorldOffset; skipping navmesh")
		return

	_nav_region = NavigationRegion3D.new()
	_nav_region.name = "CompanionNavRegion"
	world_offset.add_child(_nav_region)

	# Match the nav map cell dims to the baked navmesh to avoid rasterisation mismatch warnings.
	var map: RID = _nav_region.get_navigation_map()
	NavigationServer3D.map_set_cell_size(map, Config.NAV_CELL_SIZE)
	NavigationServer3D.map_set_cell_height(map, Config.NAV_CELL_HEIGHT)

	var baked: NavigationMesh = load(Config.PLAYGROUND_NAVMESH_PATH) as NavigationMesh
	if baked != null:
		_nav_region.navigation_mesh = baked
		return

	push_warning("Playground: baked navmesh missing at %s; baking at runtime" % Config.PLAYGROUND_NAVMESH_PATH)
	_nav_region.navigation_mesh = _runtime_navigation_mesh()
	_nav_region.call_deferred("bake_navigation_mesh", false)


func _runtime_navigation_mesh() -> NavigationMesh:
	for source_path in NAV_SOURCE_PATHS:
		var node := get_node_or_null(source_path)
		if node != null:
			node.add_to_group(Config.NAV_SOURCE_GROUP)

	var nav_mesh := NavigationMesh.new()
	nav_mesh.cell_size = Config.NAV_CELL_SIZE
	nav_mesh.cell_height = Config.NAV_CELL_HEIGHT
	nav_mesh.agent_radius = Config.NAV_AGENT_RADIUS
	nav_mesh.agent_height = Config.NAV_AGENT_HEIGHT
	nav_mesh.agent_max_climb = Config.NAV_AGENT_MAX_CLIMB
	nav_mesh.agent_max_slope = Config.NAV_AGENT_MAX_SLOPE_DEG
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav_mesh.geometry_source_group_name = Config.NAV_SOURCE_GROUP
	return nav_mesh


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
