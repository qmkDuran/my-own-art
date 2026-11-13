class_name Obb2d
## Overlap depth of two box collision shapes seen from above (separating-axis test on their footprints).


## How deep two boxes' footprints overlap (0 when they are apart).
static func overlap(a: CollisionShape3D, b: CollisionShape3D) -> float:
	var axes: Array[Vector2] = [_axis(a, Vector3.RIGHT), _axis(a, Vector3.BACK), _axis(b, Vector3.RIGHT),
		_axis(b, Vector3.BACK)]
	var depth: float = INF
	for axis: Vector2 in axes:
		var span_a: Vector2 = _span(a, axis)
		var span_b: Vector2 = _span(b, axis)
		var amount: float = minf(span_a.y, span_b.y) - maxf(span_a.x, span_b.x)
		if amount <= 0.0:
			return 0.0
		depth = minf(depth, amount)
	return depth


static func _axis(shape: CollisionShape3D, local: Vector3) -> Vector2:
	var world: Vector3 = shape.global_basis * local
	return Vector2(world.x, world.z).normalized()


static func _span(shape: CollisionShape3D, axis: Vector2) -> Vector2:
	var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
	var low: float = INF
	var high: float = -INF
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var corner: Vector3 = shape.global_transform * Vector3(half.x * sx, 0.0, half.z * sz)
			var along: float = Vector2(corner.x, corner.z).dot(axis)
			low = minf(low, along)
			high = maxf(high, along)
	return Vector2(low, high)
