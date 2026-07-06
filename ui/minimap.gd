extends Control
## Top-right overhead map — collision grid + entity dots (toggle M).

const BORDER := 2.0
const MinimapLogicScript := preload("res://core/ui/minimap_logic.gd")


func _ready() -> void:
	_update_minimap_size()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_visibility()
	GameSettings.settings_changed.connect(_on_settings_changed)


func _on_settings_changed() -> void:
	_update_minimap_size()
	queue_redraw()


func _update_minimap_size() -> void:
	var panel_size := float(GameSettings.minimap_panel_size)
	custom_minimum_size = Vector2(panel_size, panel_size)


func _process(_delta: float) -> void:
	if visible != GameState.show_minimap:
		_update_visibility()
	queue_redraw()


func _update_visibility() -> void:
	visible = GameState.show_minimap


func _draw() -> void:
	var grid: CollisionGrid = GameState.collision_grid
	if grid == null:
		return

	var panel_size := float(GameSettings.minimap_panel_size)
	var outer := panel_size + BORDER * 2.0
	draw_rect(Rect2(Vector2.ZERO, Vector2(outer, outer)), Color(0.05, 0.08, 0.12, 0.92))
	draw_rect(Rect2(Vector2(BORDER, BORDER), Vector2(panel_size, panel_size)), Color(0.12, 0.16, 0.2, 1.0))

	var cell_w := panel_size / float(grid.width)
	var cell_h := panel_size / float(grid.height)
	for z in grid.height:
		for x in grid.width:
			var colour := Config.COLOR_GROUND.darkened(0.15)
			if grid.is_cell_solid(x, z):
				colour = Config.COLOR_STONE.darkened(0.2)
			draw_rect(
				Rect2(
					Vector2(BORDER + float(x) * cell_w, BORDER + float(z) * cell_h),
					Vector2(cell_w + 0.5, cell_h + 0.5),
				),
				colour,
			)

	_draw_entity_dots(grid, panel_size)


func _draw_entity_dots(grid: CollisionGrid, panel_size: float) -> void:
	var player: CharacterBody3D = GameState.player
	if player != null:
		var player_feet := Vector2(player.global_position.x, player.global_position.z)
		var dot: Vector2 = MinimapLogicScript.world_to_panel(
			player_feet,
			grid.width,
			grid.height,
			panel_size,
		)
		dot = MinimapLogicScript.clamp_dot(dot, panel_size, 3.0)
		draw_circle(Vector2(BORDER, BORDER) + dot, 3.0, Config.COLOR_PLAYER)

	for companion in GameState.companions:
		if companion == null or not is_instance_valid(companion):
			continue
		var feet := Vector2(companion.global_position.x, companion.global_position.z)
		var dot: Vector2 = MinimapLogicScript.world_to_panel(feet, grid.width, grid.height, panel_size)
		dot = MinimapLogicScript.clamp_dot(dot, panel_size, 2.0)
		draw_circle(Vector2(BORDER, BORDER) + dot, 2.0, Config.COLOR_COMPANION)

	for npc in GameState.npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var feet := Vector2(npc.global_position.x, npc.global_position.z)
		var dot: Vector2 = MinimapLogicScript.world_to_panel(feet, grid.width, grid.height, panel_size)
		dot = MinimapLogicScript.clamp_dot(dot, panel_size, 2.0)
		draw_circle(Vector2(BORDER, BORDER) + dot, 2.0, Config.COLOR_NPC)
