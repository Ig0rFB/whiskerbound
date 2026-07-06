extends Control
## Pause overlay — resume, settings, save/load, quit (Esc).

signal resume_requested
signal quit_requested
signal save_game_requested
signal load_game_requested

enum Page { MAIN, SETTINGS }

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var _status_label: Label = $Panel/Margin/VBox/StatusLabel
@onready var _main_page: Control = $Panel/Margin/VBox/MainPage
@onready var _settings_page: Control = $Panel/Margin/VBox/SettingsPage
@onready var _resume_button: Button = $Panel/Margin/VBox/MainPage/ResumeButton
@onready var _settings_button: Button = $Panel/Margin/VBox/MainPage/SettingsButton
@onready var _save_button: Button = $Panel/Margin/VBox/MainPage/SaveButton
@onready var _load_button: Button = $Panel/Margin/VBox/MainPage/LoadButton
@onready var _quit_button: Button = $Panel/Margin/VBox/MainPage/QuitButton
@onready var _resolution_option: OptionButton = (
	$Panel/Margin/VBox/SettingsPage/SettingsScroll/SettingsVBox/ResolutionRow/ResolutionOption
)
@onready var _minimap_slider: HSlider = (
	$Panel/Margin/VBox/SettingsPage/SettingsScroll/SettingsVBox/MinimapRow/MinimapSlider
)
@onready var _minimap_value_label: Label = (
	$Panel/Margin/VBox/SettingsPage/SettingsScroll/SettingsVBox/MinimapRow/MinimapHeader/MinimapValue
)
@onready var _settings_save_button: Button = (
	$Panel/Margin/VBox/SettingsPage/SettingsScroll/SettingsVBox/SettingsSaveButton
)
@onready var _settings_load_button: Button = (
	$Panel/Margin/VBox/SettingsPage/SettingsScroll/SettingsVBox/SettingsLoadButton
)
@onready var _settings_back_button: Button = $Panel/Margin/VBox/SettingsPage/SettingsBackButton

var _page := Page.MAIN
var _syncing_settings := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_populate_resolution_options()
	_resume_button.pressed.connect(_on_resume_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_back_button.pressed.connect(_on_settings_back_pressed)
	_settings_save_button.pressed.connect(_on_save_pressed)
	_settings_load_button.pressed.connect(_on_load_pressed)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_minimap_slider.value_changed.connect(_on_minimap_slider_changed)


func open() -> void:
	_show_page(Page.MAIN)
	_refresh_load_buttons()
	set_status_message("")
	visible = true
	_resume_button.grab_focus()


func close() -> void:
	visible = false
	_show_page(Page.MAIN)


func set_status_message(text: String) -> void:
	_status_label.text = text
	_status_label.visible = not text.is_empty()


func process_gamepad() -> void:
	if not visible:
		return
	if not InputActions.confirm_pressed:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is BaseButton:
		(focus as BaseButton).pressed.emit()


func handle_back() -> bool:
	if not visible:
		return false
	if _page == Page.SETTINGS:
		_show_page(Page.MAIN)
		set_status_message("")
		return true
	return false


func _show_page(page: Page) -> void:
	_page = page
	_main_page.visible = page == Page.MAIN
	_settings_page.visible = page == Page.SETTINGS
	_title_label.text = "Settings" if page == Page.SETTINGS else "Paused"
	if page == Page.SETTINGS:
		_sync_settings_ui()
		_settings_back_button.grab_focus()
	else:
		_resume_button.grab_focus()


func _populate_resolution_options() -> void:
	_resolution_option.clear()
	for preset in GameSettings.RESOLUTION_PRESETS:
		_resolution_option.add_item(GameSettings.resolution_label(preset))


func _sync_settings_ui() -> void:
	_syncing_settings = true
	_resolution_option.select(GameSettings.get_resolution_index())
	_minimap_slider.min_value = GameSettings.MINIMAP_SIZE_MIN
	_minimap_slider.max_value = GameSettings.MINIMAP_SIZE_MAX
	_minimap_slider.step = GameSettings.MINIMAP_SIZE_STEP
	_minimap_slider.value = GameSettings.minimap_panel_size
	_update_minimap_label(int(_minimap_slider.value))
	_refresh_load_buttons()
	_syncing_settings = false


func _refresh_load_buttons() -> void:
	var has_save := SaveGame.has_save()
	_load_button.disabled = not has_save
	_settings_load_button.disabled = not has_save


func _update_minimap_label(size: int) -> void:
	_minimap_value_label.text = "%d px" % size


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_settings_pressed() -> void:
	_show_page(Page.SETTINGS)


func _on_settings_back_pressed() -> void:
	_show_page(Page.MAIN)


func _on_save_pressed() -> void:
	save_game_requested.emit()
	_refresh_load_buttons()


func _on_load_pressed() -> void:
	load_game_requested.emit()
	_refresh_load_buttons()


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _on_resolution_selected(index: int) -> void:
	if _syncing_settings:
		return
	if index < 0 or index >= GameSettings.RESOLUTION_PRESETS.size():
		return
	var preset := GameSettings.RESOLUTION_PRESETS[index]
	GameSettings.set_resolution(preset.x, preset.y)


func _on_minimap_slider_changed(value: float) -> void:
	if _syncing_settings:
		return
	var size := int(value)
	_update_minimap_label(size)
	GameSettings.set_minimap_size(size)
