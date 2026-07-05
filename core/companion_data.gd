class_name CompanionData
## Per-companion path and stuck state (ported from 2D prototype Companion_Data).

var path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var repath_timer: float = 0.0
var stuck_timer: float = 0.0
var last_progress_pos: Vector2 = Vector2.ZERO
var idle_timer: float = 0.0


func clear_path() -> void:
	path = PackedVector2Array()
	path_index = 0
