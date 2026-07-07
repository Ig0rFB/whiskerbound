extends SceneTree
## Offline navmesh bake for the playground (PROJECT.md §4).
## Bakes a NavigationMesh from the playground's CSG geometry and saves it to
## Config.PLAYGROUND_NAVMESH_PATH so the game ships a pre-baked resource (no runtime mesh parsing).
##
## Run: godot --headless --path <project> --script res://scenes/tools/bake_playground_navmesh.gd
## Re-run whenever the playground's walkable geometry changes, then commit the updated .tres.

const SOURCE_PATHS := [
	"WorldOffset/Structures/CSGCombiner3D",
	"WorldOffset/Structures/Ground/GroundMesh",
]


func _initialize() -> void:
	var playground: Node3D = load("res://scenes/areas/playground.tscn").instantiate()
	root.add_child(playground)
	await process_frame
	await process_frame

	var world_offset := playground.get_node_or_null("WorldOffset") as Node3D
	if world_offset == null:
		push_error("BAKE_FAIL: no WorldOffset")
		quit(1)
		return

	for source_path in SOURCE_PATHS:
		var node := playground.get_node_or_null(source_path)
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

	# Bake with the region parented under WorldOffset so vertices are stored relative to the
	# same transform the runtime region uses.
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav_mesh
	world_offset.add_child(region)
	region.bake_navigation_mesh(false)

	var baked: NavigationMesh = region.navigation_mesh
	if baked.get_polygon_count() <= 0:
		push_error("BAKE_FAIL: navmesh has no polygons")
		quit(1)
		return

	var err := ResourceSaver.save(baked, Config.PLAYGROUND_NAVMESH_PATH)
	if err != OK:
		push_error("BAKE_FAIL: save error %d" % err)
		quit(1)
		return

	print("BAKE_OK: %d polygons, %d vertices -> %s" % [
		baked.get_polygon_count(), baked.get_vertices().size(), Config.PLAYGROUND_NAVMESH_PATH])
	quit(0)
