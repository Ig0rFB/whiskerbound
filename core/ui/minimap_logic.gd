class_name MinimapLogic
## Pure minimap coordinate helpers — no Node dependencies.


static func world_to_panel(
	world_pos: Vector2,
	grid_width: int,
	grid_height: int,
	panel_size: float,
) -> Vector2:
	if grid_width <= 0 or grid_height <= 0:
		return Vector2.ZERO

	var scale := panel_size / float(maxi(grid_width, grid_height))
	return Vector2(world_pos.x * scale, world_pos.y * scale)


static func clamp_dot(dot: Vector2, panel_size: float, radius: float) -> Vector2:
	var inset := radius + 1.0
	var max_pos := panel_size - inset
	return Vector2(
		clampf(dot.x, inset, max_pos),
		clampf(dot.y, inset, max_pos),
	)
