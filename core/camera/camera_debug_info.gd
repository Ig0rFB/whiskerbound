extends RefCounted
## Reads third-person camera stats for the debug HUD.

static func get_distance(camera_rig: Node3D) -> float:
	if camera_rig == null:
		return 0.0
	if camera_rig.has_method("get_camera_distance"):
		return camera_rig.get_camera_distance()
	if camera_rig.has_method("get_preview_distance"):
		return camera_rig.get_preview_distance()
	var spring := _find_spring_arm(camera_rig)
	return spring.spring_length if spring else 0.0


static func get_pitch_degrees(camera_rig: Node3D) -> float:
	if camera_rig == null:
		return 0.0
	if camera_rig.has_method("get_camera_pitch_degrees"):
		return camera_rig.get_camera_pitch_degrees()
	if camera_rig.has_method("get_current_pitch_degrees"):
		return camera_rig.get_current_pitch_degrees()
	return rad_to_deg(camera_rig.rotation.x)


static func _find_spring_arm(root: Node) -> SpringArm3D:
	if root is SpringArm3D:
		return root as SpringArm3D
	for child in root.get_children():
		var found := _find_spring_arm(child)
		if found != null:
			return found
	return null
