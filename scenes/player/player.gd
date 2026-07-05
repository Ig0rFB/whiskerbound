extends CharacterBody3D
## Player avatar — movement added in M2 (PROJECT.md §9.1).


func _physics_process(_delta: float) -> void:
	# Keep feet on the ground plane until height zones exist.
	var pos := global_position
	pos.y = 0.0
	global_position = pos
