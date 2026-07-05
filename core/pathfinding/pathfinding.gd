class_name GridPathfinding
## AStarGrid2D wrapper for area collision grids.


static func build_from_grid(grid: CollisionGrid) -> AStarGrid2D:
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, grid.width, grid.height)
	astar.cell_size = Vector2(grid.cell_size, grid.cell_size)
	astar.offset = Vector2.ZERO
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	for z in grid.height:
		for x in grid.width:
			astar.set_point_solid(Vector2i(x, z), grid.is_cell_solid(x, z))

	astar.update()
	return astar


static func world_to_cell(world_pos: Vector2) -> Vector2i:
	return CollisionGrid.world_to_cell(world_pos)


static func find_path(
	astar: AStarGrid2D,
	grid: CollisionGrid,
	from_world: Vector2,
	to_world: Vector2,
) -> PackedVector2Array:
	var from_cell := world_to_cell(from_world)
	var to_cell := world_to_cell(to_world)

	if grid.is_cell_solid(from_cell.x, from_cell.y):
		return PackedVector2Array()
	if grid.is_cell_solid(to_cell.x, to_cell.y):
		return PackedVector2Array()
	if from_cell == to_cell:
		if from_world.distance_squared_to(to_world) < 0.0001:
			return PackedVector2Array()
		return PackedVector2Array([to_world])

	var id_path := astar.get_id_path(from_cell, to_cell)
	if id_path.is_empty():
		return PackedVector2Array()

	var waypoints := PackedVector2Array()
	for cell in id_path:
		waypoints.append(CollisionGrid.cell_center(cell, grid.cell_size))
	return waypoints
