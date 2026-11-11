class_name LabelStack
extends Node
## Keeps item names from overlapping: a name that would cover another is lifted a row at a time.

const ROW: float = 14.0
const MAX_LIFT_ROWS: int = 16

static var shown: bool = true


func _process(_delta: float) -> void:
	var items: Array = get_tree().get_nodes_in_group("ground_items")
	items.sort_custom(func(a: GroundItem, b: GroundItem) -> bool: return a.global_position.y > b.global_position.y)
	var placed: Array[Rect2] = []
	for g: GroundItem in items:
		g.stack_lift = 0.0
		var r: Rect2 = g.label_rect()
		var guard: int = 0
		while placed.any(func(o: Rect2) -> bool: return o.grow(1.0).intersects(r)) and guard < MAX_LIFT_ROWS:
			g.stack_lift += ROW
			r = g.label_rect()
			guard += 1
		placed.append(r)


static func overlaps(tree: SceneTree) -> int:
	var rects: Array[Rect2] = []
	for g: Node in tree.get_nodes_in_group("ground_items"):
		rects.append((g as GroundItem).label_rect())
	var n: int = 0
	for i: int in rects.size():
		for j: int in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				n += 1
	return n
