class_name WhiskerboundPlayer
extends "res://scenes/player/gdquest/StateMachine/player_character_script.gd"
## Whiskerbound adapter — reference GDQuest player with GameState hooks only.

var feet_velocity: Vector2 = Vector2.ZERO

var _last_feet: Vector2 = Vector2.ZERO


func _ready() -> void:
	super._ready()
	_disable_embedded_debug_hud()
	call_deferred("_bind_to_game_state")
	call_deferred("_bind_interaction_ray_exceptions")


func _disable_embedded_debug_hud() -> void:
	## Reference player ships a CanvasLayer debug HUD; Whiskerbound uses ui/game_ui DebugHud instead.
	if debug_hud == null:
		return
	debug_hud.visible = false
	debug_hud.process_mode = Node.PROCESS_MODE_DISABLED


func display_properties() -> void:
	pass


func _process(delta: float) -> void:
	modify_model_orientation(delta)


func _physics_process(delta: float) -> void:
	if GameState.mode != GameState.GameMode.GAMEPLAY:
		velocity.x = 0.0
		velocity.z = 0.0
		if is_on_floor():
			velocity.y = 0.0
		else:
			gravity_apply(delta)
		move_and_slide()
		_update_feet_velocity(delta)
		return
	super._physics_process(delta)
	_update_feet_velocity(delta)


func handle_interaction() -> void:
	_bind_interaction_ray_exceptions()
	interaction_raycast.global_transform.basis = cam_holder.cam.global_transform.basis
	interaction_raycast.force_raycast_update()

	var target_name := ""
	var interactable_owner: Node = null
	if interaction_raycast.is_colliding():
		var collider: Object = interaction_raycast.get_collider()
		if collider is Node:
			interactable_owner = _find_interactable_owner(collider as Node)

		if interactable_owner != null:
			target_name = interactable_owner.name

	_sync_interact_target(target_name, interactable_owner)


func _find_interactable_owner(from: Node) -> Node:
	var node: Node = from
	while node != null:
		if node.has_node("Interactable"):
			return node
		node = node.get_parent()
	return null


func face_toward_world(target_feet: Vector2) -> void:
	var feet := Vector2(global_position.x, global_position.z)
	var direction := target_feet - feet
	if direction.length_squared() < 0.0001:
		return
	var target_angle := -direction.orthogonal().angle()
	visual_root.rotation.y = target_angle


func capture_camera_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_camera_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func set_camera_input_enabled(enabled: bool) -> void:
	if cam_holder != null:
		cam_holder.set_active(enabled)


func set_camera_distance(dist: float) -> void:
	if cam_holder == null:
		return
	cam_holder.zoom_val = clampf(dist, cam_holder.min_zoom_val, cam_holder.max_zoom_val)


func _bind_camera_to_game_state() -> void:
	_bind_to_game_state()


func _bind_to_game_state() -> void:
	GameState.player = self
	if cam_holder != null:
		GameState.camera_rig = cam_holder


func _bind_interaction_ray_exceptions() -> void:
	if interaction_raycast == null:
		return
	interaction_raycast.add_exception(self)
	for companion in GameState.companions:
		if companion is CollisionObject3D:
			interaction_raycast.add_exception(companion as CollisionObject3D)


func _sync_interact_target(target_name: String, target_owner: Node) -> void:
	if GameState.interact_target_name == target_name and GameState.interact_target_owner == target_owner:
		return
	GameState.interact_target_name = target_name
	GameState.interact_target_owner = target_owner
	Events.interact_target_changed.emit(target_name)


func _update_feet_velocity(delta: float) -> void:
	var feet := Vector2(global_position.x, global_position.z)
	if delta > 0.0:
		feet_velocity = (feet - _last_feet) / delta
	else:
		feet_velocity = Vector2.ZERO
	_last_feet = feet
