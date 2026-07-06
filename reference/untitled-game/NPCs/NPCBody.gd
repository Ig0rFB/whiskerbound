extends CharacterBody3D

enum MotionType { GROUNDED, FLOATING }
@export var motion_type : MotionType = MotionType.GROUNDED

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	if motion_type == MotionType.FLOATING:
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	else:
		motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

func _physics_process(delta):
	# When motion_mode is FLOATING, Godot automatically ignores gravity for this body.
	# We only need to manually apply gravity for our GROUNDED characters.
	if motion_mode == CharacterBody3D.MOTION_MODE_GROUNDED and not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()
