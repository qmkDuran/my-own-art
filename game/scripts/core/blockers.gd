class_name Blockers
extends RefCounted
## Static rectangle colliders: the "solid ground truth" of each scene, always matching the art.


static func add(parent: Node, r: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.position + r.size / 2.0
	body.add_child(shape)
	parent.add_child(body)
	return body


## Rects given as [x, y, w, h] arrays (from scene data).
static func add_all(parent: Node, rects: Array) -> void:
	for r: Array in rects:
		add(parent, SceneData.rect(r))


## A collider on the ground at an object's feet: `size` wide, centred on x, ending `below` px under the feet.
static func footprint(parent: Node, feet: Vector2, size: Vector2, below: float = 0.0) -> void:
	add(parent, Rect2(feet.x - size.x / 2.0, feet.y - size.y + below, size.x, size.y))
