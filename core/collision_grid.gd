class_name CollisionGrid
## 2D solid/walkable grid on the XZ plane (ported from 2D prototype world.odin).

const DEFAULT_COLLISION_INSET := 0.1

var width: int = 0
var height: int = 0
var cell_size: float = 1.0

var _solid: PackedByteArray = PackedByteArray()


func configure(grid_width: int, grid_height: int, grid_cell_size: float = 1.0) -> void:
	width = grid_width
	height = grid_height
	cell_size = grid_cell_size
	_solid = PackedByteArray()
	_solid.resize(width * height)
	_solid.fill(0)


func set_solid(cell_x: int, cell_z: int, solid: bool) -> void:
	if cell_x < 0 or cell_z < 0 or cell_x >= width or cell_z >= height:
		return
	_solid[cell_z * width + cell_x] = 1 if solid else 0


func is_cell_solid(cell_x: int, cell_z: int) -> bool:
	if cell_x < 0 or cell_z < 0 or cell_x >= width or cell_z >= height:
		return true
	if _solid.is_empty():
		return false
	return _solid[cell_z * width + cell_x] != 0


func _collision_sample_inset(collider: Rect2) -> float:
	var max_inset := collider.size.x * 0.4
	if DEFAULT_COLLISION_INSET < max_inset:
		return DEFAULT_COLLISION_INSET
	return max_inset


## True when any collision cell overlaps the entity footprint (XZ plane).
func entity_blocked(feet_x: float, feet_z: float, collider: Rect2) -> bool:
	if _solid.is_empty():
		return false

	var inset := _collision_sample_inset(collider)
	var world_rect := Rect2(
		feet_x + collider.position.x + inset,
		feet_z + collider.position.y + inset,
		collider.size.x - inset * 2.0,
		collider.size.y - inset * 2.0,
	)
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return false

	var min_cx := int(floor(world_rect.position.x / cell_size))
	var max_cx := int(floor((world_rect.position.x + world_rect.size.x - 1e-5) / cell_size))
	var min_cz := int(floor(world_rect.position.y / cell_size))
	var max_cz := int(floor((world_rect.position.y + world_rect.size.y - 1e-5) / cell_size))

	for cz in range(min_cz, max_cz + 1):
		for cx in range(min_cx, max_cx + 1):
			if is_cell_solid(cx, cz):
				return true
	return false
