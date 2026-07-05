class_name CompanionCollider
## Smaller feet footprint for Lumi (PROJECT.md §14 — sphere r=0.2).

const FEET_RADIUS := 0.2


static func feet_rect() -> Rect2:
	var diameter := FEET_RADIUS * 2.0
	return Rect2(-FEET_RADIUS, -FEET_RADIUS, diameter, diameter)
