class_name CompanionData
## Per-companion path and stuck state (ported from 2D prototype Companion_Data).

var path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var repath_timer: float = 0.0
var stuck_timer: float = 0.0
var last_progress_pos: Vector2 = Vector2.ZERO
var last_repath_player_pos: Vector2 = Vector2(INF, INF)
var idle_timer: float = 0.0
var slot_lateral_offset: float = 0.0
var idle_ring_offset: Vector2 = Vector2.ZERO
var activity: CompanionActivity.Type = CompanionActivity.Type.NONE
var activity_timer: float = 0.0
var wander_target: Vector2 = Vector2.ZERO
var meow_cooldown: float = 0.0


func configure_slot(slot: int) -> void:
	var angle := float(slot) * 1.2
	slot_lateral_offset = sin(angle) * Config.COMPANION_SLOT_LATERAL
	var ring := CompanionLogic.follow_distance(slot) * 0.55
	idle_ring_offset = Vector2(cos(angle), sin(angle)) * ring
	meow_cooldown = randf_range(
		Config.COMPANION_MEOW_MIN_INTERVAL * 0.5,
		Config.COMPANION_MEOW_MAX_INTERVAL,
	)


func reset_autonomous() -> void:
	activity = CompanionActivity.Type.NONE
	activity_timer = 0.0
	wander_target = Vector2.ZERO
	clear_path()


func clear_path() -> void:
	path = PackedVector2Array()
	path_index = 0
