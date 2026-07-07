extends Node
## Player preferences — persisted to disk and applied at runtime.

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "game"

const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1440),
	Vector2i(2560, 1600),
	Vector2i(3200, 1800),
	Vector2i(3440, 1440),
	Vector2i(3840, 2160),
]

## Fixed design resolution the UI is authored against. Canvas items scale by window / this, so the
## HUD, minimap, and menus grow with resolution while the 3D world renders at the window's size.
const UI_BASE_RESOLUTION := Vector2i(1920, 1080)

const MINIMAP_SIZE_MIN := 180
const MINIMAP_SIZE_MAX := 400
const MINIMAP_SIZE_STEP := 8

var minimap_panel_size: int = Config.MINIMAP_PANEL_SIZE
var viewport_width: int = Config.VIEWPORT_WIDTH
var viewport_height: int = Config.VIEWPORT_HEIGHT


func _ready() -> void:
	load_settings()
	call_deferred("apply_viewport")


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return

	minimap_panel_size = int(
		file.get_value(SECTION, "minimap_panel_size", Config.MINIMAP_PANEL_SIZE)
	)
	viewport_width = int(file.get_value(SECTION, "viewport_width", Config.VIEWPORT_WIDTH))
	viewport_height = int(
		file.get_value(SECTION, "viewport_height", Config.VIEWPORT_HEIGHT)
	)


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value(SECTION, "minimap_panel_size", minimap_panel_size)
	file.set_value(SECTION, "viewport_width", viewport_width)
	file.set_value(SECTION, "viewport_height", viewport_height)
	file.save(SETTINGS_PATH)


func set_minimap_size(size: int) -> void:
	var clamped := clampi(size, MINIMAP_SIZE_MIN, MINIMAP_SIZE_MAX)
	if minimap_panel_size == clamped:
		return
	minimap_panel_size = clamped
	save_settings()
	settings_changed.emit()


func set_resolution(width: int, height: int) -> void:
	if viewport_width == width and viewport_height == height:
		return
	viewport_width = width
	viewport_height = height
	save_settings()
	apply_viewport()
	settings_changed.emit()


func apply_viewport() -> void:
	if not is_inside_tree():
		return
	var window := get_window()
	window.size = Vector2i(viewport_width, viewport_height)
	# Scale the UI up with resolution: canvas-item stretch against a fixed design base. The 3D
	# world still renders at the full window size, so only the 2D UI grows.
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_size = UI_BASE_RESOLUTION


func get_resolution_index() -> int:
	for i in RESOLUTION_PRESETS.size():
		var preset := RESOLUTION_PRESETS[i]
		if preset.x == viewport_width and preset.y == viewport_height:
			return i
	return RESOLUTION_PRESETS.size() - 1


func resolution_label(preset: Vector2i) -> String:
	return "%d × %d" % [preset.x, preset.y]
