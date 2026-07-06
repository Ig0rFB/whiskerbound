class_name GroundedCharacter
extends CharacterBody3D
## Default physics body for companions and NPCs — gravity, floor snap, capsule collision.
##
## Implementation guide: PROJECT.md §9.0

@export var body_radius: float = Config.CHARACTER_BODY_RADIUS
@export var body_height: float = Config.CHARACTER_BODY_HEIGHT


func _ready() -> void:
	_apply_body_defaults()
	_ensure_collision_shape()
	call_deferred("snap_to_floor")


func _apply_body_defaults() -> void:
	motion_mode = MOTION_MODE_GROUNDED
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(46.0)
	collision_layer = Config.COLLISION_LAYER_CHARACTER
	collision_mask = Config.COLLISION_LAYER_WORLD
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true


func _ensure_collision_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		add_child(shape_node)

	var capsule := shape_node.shape as CapsuleShape3D
	if capsule == null:
		capsule = CapsuleShape3D.new()
		shape_node.shape = capsule

	capsule.radius = body_radius
	capsule.height = maxf(body_height - body_radius * 2.0, 0.05)
	shape_node.position.y = body_height * 0.5


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
		return
	velocity.y -= _gravity_strength() * delta


func snap_to_floor() -> void:
	if not is_inside_tree():
		return
	velocity = Vector3.ZERO
	for _attempt in 4:
		velocity.y = -4.0
		move_and_slide()
		if is_on_floor():
			break
	velocity = Vector3.ZERO


static func _gravity_strength() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
