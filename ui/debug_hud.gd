extends Control
## Unified debug HUD — Whiskerbound stats + third-person controller readouts (toggle H).

const CameraDebugInfoScript := preload("res://core/camera/camera_debug_info.gd")

const PANEL_BG := Color(0.05, 0.08, 0.12, 0.9)
const PANEL_BORDER := Color(0.35, 0.45, 0.55, 0.9)
const TEXT_MAIN := Color(0.94, 0.96, 1.0, 1.0)
const MARGIN := 16
const PAD := 12
const FONT_MAIN := 24
const FONT_SECTION := 22
const FONT_DETAIL := 20
const FONT_SHORTCUT := 19
const POSITION_PANEL_GAP := 16.0


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

	_draw_left_panel()
	_draw_right_panel()


func _draw_left_panel() -> void:
	var lines: PackedStringArray = []
	var font_sizes: PackedInt32Array = []

	_append_line(lines, font_sizes, "FPS: %d" % Engine.get_frames_per_second(), FONT_MAIN)
	_append_line(lines, font_sizes, _area_line(), FONT_MAIN)
	_append_line(lines, font_sizes, _mode_line(), FONT_MAIN)
	_append_line(lines, font_sizes, "Companions: %d" % GameState.companions.size(), FONT_MAIN)
	_append_line(lines, font_sizes, "Colliders: %s" % _on_off(GameState.show_collision_debug), FONT_MAIN)
	_append_line(lines, font_sizes, "Path: %s" % _on_off(GameState.show_debug_hud), FONT_MAIN)

	_append_line(lines, font_sizes, "— Player —", FONT_SECTION)
	for line in _player_debug_lines():
		_append_line(lines, font_sizes, line, FONT_DETAIL)

	_append_line(lines, font_sizes, "— Shortcuts —", FONT_SECTION)
	for line in _shortcut_lines():
		_append_line(lines, font_sizes, line, FONT_SHORTCUT)

	var panel_size := _measure_panel(lines, font_sizes)
	var origin := Vector2(MARGIN, MARGIN)
	_draw_panel(origin, panel_size)
	_draw_lines(origin, lines, font_sizes)


func _draw_right_panel() -> void:
	var player: CharacterBody3D = GameState.player
	var grid: CollisionGrid = GameState.collision_grid
	if player == null or grid == null:
		return

	var feet := Vector2(player.global_position.x, player.global_position.z)
	var tile_x := int(floorf(feet.x))
	var tile_z := int(floorf(feet.y))
	var lines: PackedStringArray = [
		"Pos (%.2f, %.2f)" % [feet.x, feet.y],
		"Height: %.2f" % player.global_position.y,
		"Tile [%d, %d]" % [tile_x, tile_z],
		"Walk: %s" % _walk_label(feet, grid),
	]
	lines.append_array(_camera_debug_lines())

	var font_sizes := PackedInt32Array()
	font_sizes.resize(lines.size())
	font_sizes.fill(FONT_DETAIL)

	var panel_size := _measure_panel(lines, font_sizes)
	var minimap_size := float(GameSettings.minimap_panel_size)
	var minimap_bottom := Config.MINIMAP_MARGIN + minimap_size + 4.0 + POSITION_PANEL_GAP
	var origin := Vector2(
		get_viewport_rect().size.x - panel_size.x - Config.MINIMAP_MARGIN,
		minimap_bottom,
	)
	_draw_panel(origin, panel_size)
	_draw_lines(origin, lines, font_sizes)


func _player_debug_lines() -> PackedStringArray:
	var player: CharacterBody3D = GameState.player
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return PackedStringArray(["State: —"])

	if not ("state_machine" in player):
		return PackedStringArray(["State: —"])

	var lines: PackedStringArray = [
		"State: %s" % player.state_machine.curr_state_name,
		"Speed: %.2f" % player.velocity.length(),
		"On floor: %s" % str(player.is_on_floor()),
		"Air jumps: %d" % player.nb_jumps_in_air_allowed,
	]

	if "cam_holder" in player and player.cam_holder != null:
		var cam = player.cam_holder
		lines.append("Cam mode: %s" % ("aim" if cam.cam_aimed else "default"))
		lines.append("Cam collision: %s" % _on_off(cam.cam_collision_enabled))
		if "follow_cam_pos_when_aimed" in player:
			var orient := "cam follower" if (cam.cam_aimed and player.follow_cam_pos_when_aimed) else "independent"
			lines.append("Model facing: %s" % orient)

	return lines


func _shortcut_lines() -> PackedStringArray:
	return PackedStringArray([
		"WASD / stick — move",
		"Shift / Y — run",
		"Space / A — jump",
		"Mouse / R-stick — look",
		"Wheel / V — zoom in",
		"Wheel / B — zoom out",
		"L2 / R2 — zoom out / in",
		"RMB / R-shoulder — aim cam",
		"G — swap aim shoulder",
		"T — toggle cam collision",
		"Ctrl / L3 — free mouse",
		"E / A — talk / advance",
		"H — debug HUD",
		"M — minimap",
		"Esc / Start — pause",
		"R — restart  C — +cat  L — reload",
	])


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


func _on_off(enabled: bool) -> String:
	return "on" if enabled else "off"


func _walk_label(feet: Vector2, grid: CollisionGrid) -> String:
	if grid.entity_blocked(feet.x, feet.y, PlayerCollider.feet_rect()):
		return "blocked"
	return "clear"


func _camera_debug_lines() -> PackedStringArray:
	var rig: Node3D = GameState.camera_rig
	if rig == null:
		return PackedStringArray([
			"Camera dist: —",
			"Camera pitch: —",
		])
	return PackedStringArray([
		"Camera dist: %.1f" % CameraDebugInfoScript.get_distance(rig),
		"Camera pitch: %.1f°" % CameraDebugInfoScript.get_pitch_degrees(rig),
	])


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
		var line_size := font_sizes[i]
		var line_h := float(line_size) + 7.0
		panel_h += line_h
		var line_w := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, line_size).x
		panel_w = maxf(panel_w, line_w + PAD * 2.0)
	return Vector2(panel_w, panel_h)


func _draw_panel(origin: Vector2, panel_size: Vector2) -> void:
	draw_rect(Rect2(origin - Vector2(2, 2), panel_size + Vector2(4, 4)), PANEL_BORDER)
	draw_rect(Rect2(origin, panel_size), PANEL_BG)


func _draw_lines(origin: Vector2, lines: PackedStringArray, font_sizes: PackedInt32Array) -> void:
	var font := ThemeDB.fallback_font
	var y := origin.y + PAD
	for i in lines.size():
		var line_size := font_sizes[i]
		var text := lines[i]
		var shadow_pos := Vector2(origin.x + PAD + 1.0, y + 1.0)
		draw_string(font, shadow_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, line_size, Color(0, 0, 0, 0.75))
		draw_string(font, Vector2(origin.x + PAD, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, line_size, TEXT_MAIN)
		y += float(line_size) + 7.0
