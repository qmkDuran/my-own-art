class_name TravelPanel
extends GamePanel
## The found waystones: click one to travel there (a short fade). Opened by using a waystone.

signal chosen(index: int)

const ROW_H: float = 22.0

var stones: Array = []


func _draw() -> void:
	frame("Waystones")
	var tip: Variant = []
	for i: int in stones.size():
		var it: Interactable = stones[i]
		var r := Rect2(16, 34 + i * ROW_H, size.x - 32, ROW_H - 4)
		var found: bool = it.opened
		UiDraw.box(self, r, Color(0.2, 0.17, 0.06) if r.has_point(hover) and found else Color(0.08, 0.07, 0.11), UiDraw.FRAME if found else Color(0.3, 0.3, 0.3))
		UiDraw.text(self, r.position + Vector2(8, 13), "%d  %s" % [i + 1, it.title] + ("" if found else "   (not found)"), Color.WHITE if found else UiDraw.DIM)
	UiDraw.tooltip(self, hover, tip)


func clicked(at: Vector2) -> void:
	for i: int in stones.size():
		if Rect2(16, 34 + i * ROW_H, size.x - 32, ROW_H - 4).has_point(at) and (stones[i] as Interactable).opened:
			chosen.emit(i)
			return
