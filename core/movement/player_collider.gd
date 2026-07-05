class_name PlayerCollider
## Feet-centred footprint on the XZ plane (capsule radius at ground level).

const FEET_RADIUS := 0.25


static func feet_rect() -> Rect2:
	var diameter := FEET_RADIUS * 2.0
	return Rect2(-FEET_RADIUS, -FEET_RADIUS, diameter, diameter)
