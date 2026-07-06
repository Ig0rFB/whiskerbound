extends "res://scenes/npc/reference/NPCBody.gd"
## Reference BaseNPC physics + Whiskerbound dialogue metadata.

const INTERACTION_COLUMN_NAME := "InteractionColumn"
const COLUMN_SHAPE_NAME := "ColumnShape"


@export var npc_id: String = ""
@export var dialogue_id: int = -1
@export var display_name: String = "???"
## When floating, stretch collision from mesh centre down to the floor for easier ray hits.
@export var interaction_column_to_ground: bool = true

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D

var _floating_column_frames_remaining: int = 0


func _ready() -> void:
	super._ready()
	if motion_type == MotionType.FLOATING and interaction_column_to_ground:
		if _collision_shape != null:
			_collision_shape.disabled = true
		_floating_column_frames_remaining = 2
	else:
		_configure_grounded_collision_shape()
	add_to_group("npcs")
	if dialogue_id < 0 and not npc_id.is_empty():
		dialogue_id = DialogueData.dialogue_id_for_npc(npc_id)
	if display_name == "???" and dialogue_id >= 0:
		display_name = DialogueData.speaker_name(dialogue_id)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _floating_column_frames_remaining <= 0:
		return
	_floating_column_frames_remaining -= 1
	if _floating_column_frames_remaining > 0:
		return
	_configure_floating_column_collision()


## Humanoid capsule for grounded NPCs.
func _configure_grounded_collision_shape() -> void:
	if _collision_shape == null:
		return

	var capsule := CapsuleShape3D.new()
	capsule.radius = Config.NPC_BODY_RADIUS
	capsule.height = Config.NPC_BODY_HEIGHT
	_collision_shape.transform = Transform3D.IDENTITY
	_collision_shape.position = Vector3(0.0, Config.NPC_BODY_HEIGHT * 0.5, 0.0)
	_collision_shape.shape = capsule
	_collision_shape.disabled = false


## Static column from mesh top to floor — floating CharacterBody3D does not block the player.
func _configure_floating_column_collision() -> void:
	if not is_inside_tree():
		return

	var ground_local_y: float = _raycast_ground_local_y()
	var mesh_bounds: Vector2 = _estimate_mesh_vertical_bounds_local()
	var top_y: float = maxf(mesh_bounds.y, Config.NPC_FLOATING_COLUMN_TOP_LOCAL)
	top_y = maxf(top_y, ground_local_y + Config.NPC_FLOATING_COLUMN_MIN_HEIGHT)
	var bottom_y: float = ground_local_y
	var span: float = maxf(top_y - bottom_y, Config.NPC_FLOATING_COLUMN_MIN_HEIGHT)
	var radius: float = Config.NPC_FLOATING_BODY_RADIUS

	var column := BoxShape3D.new()
	column.size = Vector3(radius * 2.0, span, radius * 2.0)

	var column_body: StaticBody3D = get_node_or_null(INTERACTION_COLUMN_NAME) as StaticBody3D
	if column_body == null:
		column_body = StaticBody3D.new()
		column_body.name = INTERACTION_COLUMN_NAME
		add_child(column_body)

	column_body.collision_layer = collision_layer
	column_body.collision_mask = 0

	var column_shape: CollisionShape3D = column_body.get_node_or_null(COLUMN_SHAPE_NAME) as CollisionShape3D
	if column_shape == null:
		column_shape = CollisionShape3D.new()
		column_shape.name = COLUMN_SHAPE_NAME
		column_body.add_child(column_shape)

	column_shape.transform = Transform3D.IDENTITY
	column_shape.shape = column
	column_shape.position = Vector3(0.0, bottom_y + span * 0.5, 0.0)

	if _collision_shape != null:
		_collision_shape.disabled = true


func _raycast_ground_local_y() -> float:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = global_position + Vector3.UP * Config.NPC_FLOATING_GROUND_RAY_ABOVE
	var to: Vector3 = global_position - Vector3.UP * Config.NPC_FLOATING_GROUND_RAY_BELOW
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = Config.COLLISION_LAYER_WORLD | Config.COLLISION_LAYER_CHARACTER
	query.exclude = _ground_ray_exclude_rids()
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return 0.0
	return to_local(hit.position as Vector3).y


func _ground_ray_exclude_rids() -> Array[RID]:
	var exclude: Array[RID] = [get_rid()]
	var column_body: StaticBody3D = get_node_or_null(INTERACTION_COLUMN_NAME) as StaticBody3D
	if column_body != null:
		exclude.append(column_body.get_rid())
	return exclude


func _estimate_mesh_vertical_bounds_local() -> Vector2:
	var skin_root: Node3D = _find_skin_root()
	if skin_root == null:
		return Vector2(0.0, 0.0)

	var min_y: float = INF
	var max_y: float = -INF
	var found: bool = false
	for node: Node in skin_root.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = node as VisualInstance3D
		var mesh_aabb: AABB = visual.get_aabb()
		var corners: PackedVector3Array = PackedVector3Array([
			mesh_aabb.position,
			mesh_aabb.position + Vector3(mesh_aabb.size.x, 0.0, 0.0),
			mesh_aabb.position + Vector3(0.0, mesh_aabb.size.y, 0.0),
			mesh_aabb.position + Vector3(0.0, 0.0, mesh_aabb.size.z),
			mesh_aabb.position + Vector3(mesh_aabb.size.x, mesh_aabb.size.y, 0.0),
			mesh_aabb.position + Vector3(mesh_aabb.size.x, 0.0, mesh_aabb.size.z),
			mesh_aabb.position + Vector3(0.0, mesh_aabb.size.y, mesh_aabb.size.z),
			mesh_aabb.end,
		])
		for corner: Vector3 in corners:
			var npc_local_y: float = to_local(visual.to_global(corner)).y
			min_y = minf(min_y, npc_local_y)
			max_y = maxf(max_y, npc_local_y)
			found = true

	if found:
		return Vector2(min_y, max_y)
	var skin_y: float = skin_root.position.y
	return Vector2(skin_y, skin_y)


func _find_skin_root() -> Node3D:
	for child: Node in get_children():
		if child is CollisionShape3D or child.name == "Interactable":
			continue
		if child.name == INTERACTION_COLUMN_NAME:
			continue
		if child is Node3D:
			return child as Node3D
	return null
