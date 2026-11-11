class_name RespecPanel
extends GamePanel
## Ottilie's ledger: take back every passive point, or every point in one skill's tree (free in this test).

const BTN := Vector2(240, 24)


func _row(i: int) -> Rect2:
	return Rect2(roundf((size.x - BTN.x) / 2.0), CONTENT_Y + 14.0 + i * (BTN.y + 6.0), BTN.x, BTN.y)


func _skills() -> Array[String]:
	var out: Array[String] = []
	for id: String in g.player.prog.skills:
		if not GameData.skill(id)["nodes"].is_empty():
			out.append(id)
	return out


func _content() -> void:
	button(_row(0), "Refund all passive points")
	var sk: Array[String] = _skills()
	for i: int in sk.size():
		button(_row(i + 1), "Refund %s's tree" % GameData.skill(sk[i])["name"])


func _click(at: Vector2, _button: int) -> void:
	if _row(0).has_point(at):
		g.player.prog.refund_passives()
	var sk: Array[String] = _skills()
	for i: int in sk.size():
		if _row(i + 1).has_point(at):
			g.player.prog.refund_skill(sk[i])
	Audio.sfx("ui_click", -6.0)
