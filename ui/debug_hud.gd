extends Control
## Designer debug panels — mirrors 2D prototype HUD (toggle H).

const PANEL_BG := Color(0.05, 0.08, 0.12, 0.88)
const PANEL_BORDER := Color(0.35, 0.45, 0.55, 0.9)
const TEXT_MAIN := Color(0.94, 0.96, 1.0, 1.0)
const TEXT_DIM := Color(0.72, 0.78, 0.86, 1.0)
const MARGIN := 12
const PAD := 8
const FONT_MAIN := 15
const FONT_SMALL := 13
const FONT_POS := 14


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_visibility()


func _process(_delta: float) -> void:
	if visible != GameState.show_debug_hud:
		_update_visibility()
	queue_redraw()


func _update_visibility() -> void:
	visible = GameState.show_debug_hud


func _draw() -> void:
	if not GameState.show_debug_hud:
		return

	_draw_summary_panel()
	_draw_position_panel()


func _draw_summary_panel() -> void:
	var lines: PackedStringArray = []
	var font_sizes: PackedInt32Array = []

	_append_line(lines, font_sizes, _fps_line(), FONT_MAIN)
	_append_line(lines, font_sizes, _area_line(), FONT_MAIN)
	_append_line(lines, font_sizes, _mode_line(), FONT_MAIN)
	_append_line(lines, font_sizes, "Companions: %d" % GameState.companions.size(), FONT_MAIN)
	_append_line(lines, font_sizes, "Colliders: %s" % _collision_label(), FONT_MAIN)
	_append_line(lines, font_sizes, "H HUD  M map  Esc pause", FONT_SMALL)
	_append_line(lines, font_sizes, "R restart  C +cat  L reload", FONT_SMALL)

	var panel_size := _measure_panel(lines, font_sizes)
	var origin := Vector2(MARGIN, MARGIN)
	_draw_panel(origin, panel_size)
	_draw_lines(origin, lines, font_sizes)


func _draw_position_panel() -> void:
	var player: CharacterBody3D = GameState.player
	var grid: CollisionGrid = GameState.collision_grid
	if player == null or grid == null:
		return

	var feet := Vector2(player.global_position.x, player.global_position.z)
	var tile_x := int(floorf(feet.x))
	var tile_z := int(floorf(feet.y))
	var lines: PackedStringArray = [
		"Pos (%.2f, %.2f)" % [feet.x, feet.y],
		"Tile [%d, %d]" % [tile_x, tile_z],
		"Walk: %s" % _walk_label(feet, grid),
	]
	var font_sizes := PackedInt32Array([FONT_POS, FONT_POS, FONT_POS])

	var panel_size := _measure_panel(lines, font_sizes)
	var minimap_bottom := Config.MINIMAP_MARGIN + Config.MINIMAP_PANEL_SIZE + 4.0
	var origin := Vector2(
		get_viewport_rect().size.x - panel_size.x - Config.MINIMAP_MARGIN,
		minimap_bottom,
	)
	_draw_panel(origin, panel_size)
	_draw_lines(origin, lines, font_sizes)


func _fps_line() -> String:
	return "FPS: %d" % Engine.get_frames_per_second()


func _area_line() -> String:
	var grid: CollisionGrid = GameState.collision_grid
	if grid == null:
		return "Area: %s" % GameState.current_area_id
	return "Area: %s (%dx%d)" % [GameState.current_area_id, grid.width, grid.height]


func _mode_line() -> String:
	match GameState.mode:
		GameState.GameMode.GAMEPLAY:
			return "Mode: gameplay"
		GameState.GameMode.DIALOGUE:
			return "Mode: dialogue"
		GameState.GameMode.PAUSE:
			return "Mode: pause"
		GameState.GameMode.MENU:
			return "Mode: menu"
		GameState.GameMode.INVENTORY:
			return "Mode: inventory"
	return "Mode: ?"


func _collision_label() -> String:
	return "on" if GameState.show_collision_debug else "off"


func _walk_label(feet: Vector2, grid: CollisionGrid) -> String:
	if grid.entity_blocked(feet.x, feet.y, PlayerCollider.feet_rect()):
		return "blocked"
	return "clear"


func _append_line(
	lines: PackedStringArray,
	font_sizes: PackedInt32Array,
	text: String,
	size: int,
) -> void:
	lines.append(text)
	font_sizes.append(size)


func _measure_panel(lines: PackedStringArray, font_sizes: PackedInt32Array) -> Vector2:
	var panel_w := PAD * 2.0
	var panel_h := PAD * 2.0
	var font := ThemeDB.fallback_font
	for i in lines.size():
		var size := font_sizes[i]
		var line_h := float(size) + 5.0
		panel_h += line_h
		var line_w := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		panel_w = maxf(panel_w, line_w + PAD * 2.0)
	return Vector2(panel_w, panel_h)


func _draw_panel(origin: Vector2, panel_size: Vector2) -> void:
	draw_rect(Rect2(origin - Vector2(2, 2), panel_size + Vector2(4, 4)), PANEL_BORDER)
	draw_rect(Rect2(origin, panel_size), PANEL_BG)


func _draw_lines(origin: Vector2, lines: PackedStringArray, font_sizes: PackedInt32Array) -> void:
	var font := ThemeDB.fallback_font
	var y := origin.y + PAD
	for i in lines.size():
		var size := font_sizes[i]
		var text := lines[i]
		var shadow_pos := Vector2(origin.x + PAD + 1.0, y + 1.0)
		draw_string(font, shadow_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.75))
		draw_string(font, Vector2(origin.x + PAD, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, TEXT_MAIN)
		y += float(size) + 5.0
