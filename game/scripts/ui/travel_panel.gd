class_name TravelPanel
extends GamePanel
## Nim's maps (and any lit waylamp): travel to any zone you have been to, arriving by its lit waylamp.

const ROW := Vector2(260, 24)


func zones_known() -> Array[String]:
	var out: Array[String] = []
	for id: String in GameData.zones["zones"]:
		if Session.zones.has(id) or id == g.zone_id:
			out.append(id)
	return out


func _row(i: int) -> Rect2:
	return Rect2(roundf((size.x - ROW.x) / 2.0), CONTENT_Y + 14.0 + i * (ROW.y + 6.0), ROW.x, ROW.y)


func _content() -> void:
	var known: Array[String] = zones_known()
	for i: int in known.size():
		var here: bool = known[i] == g.zone_id
		button(_row(i), String(GameData.zone(known[i])["name"]) + ("  (here)" if here else ""), not here)


func _click(at: Vector2, _button: int) -> void:
	var known: Array[String] = zones_known()
	for i: int in known.size():
		if _row(i).has_point(at) and known[i] != g.zone_id:
			var to: String = known[i]
			visible = false
			g.ui.fade_through(func() -> void: Session.travel(g, to, true))
