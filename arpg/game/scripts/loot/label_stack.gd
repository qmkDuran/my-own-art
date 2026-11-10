class_name LabelStack
extends Node
## Keeps item labels from overlapping: labels that would cover each other are lifted in rows. Alt shows/hides labels.

const ROW: float = 14.0

static var shown: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo \
			and (event as InputEventKey).physical_keycode == KEY_ALT:
		shown = not shown


func _process(_delta: float) -> void:
	var items: Array = get_tree().get_nodes_in_group("ground_items")
	items.sort_custom(func(a: GroundItem, b: GroundItem) -> bool: return a.global_position.y > b.global_position.y)
	var placed: Array[Rect2] = []
	for g: GroundItem in items:
		g.stack_lift = 0.0
		var r: Rect2 = g.label_rect()
		var guard: int = 0
		while placed.any(func(o: Rect2) -> bool: return o.intersects(r)) and guard < 12:
			g.stack_lift += ROW
			r = g.label_rect()
			guard += 1
		placed.append(r)
