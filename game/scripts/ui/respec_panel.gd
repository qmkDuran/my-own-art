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


## Ash it costs: one per passive point, one per two skill-tree points (data/crafting.json refund).
func passive_cost() -> int:
	var spent: int = 0
	for id: String in g.player.prog.passives:
		spent += int(g.player.prog.passives[id])
	return spent * int(GameData.crafting["refund"]["passive_ash_per_point"])


func skill_cost(s: String) -> int:
	return ceili(float(g.player.prog.spec_spent(s)) / float(GameData.crafting["refund"]["skill_ash_per_points"]))


func _content() -> void:
	var ash: int = g.player.inv.material("ash")
	button(_row(0), "Refund all passives (%d Ash)" % passive_cost(), ash >= passive_cost() and passive_cost() > 0)
	var sk: Array[String] = _skills()
	for i: int in sk.size():
		button(_row(i + 1), "Refund %s (%d Ash)" % [GameData.skill(sk[i])["name"], skill_cost(sk[i])], ash >= skill_cost(sk[i]) and skill_cost(sk[i]) > 0)
	UiDraw.text(self, Vector2(0, size.y - 10.0), "You have %d Ash" % ash, UiDraw.DIM, UiDraw.SMALL, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _click(at: Vector2, _button: int) -> void:
	if _row(0).has_point(at) and passive_cost() > 0 and g.player.inv.spend("ash", passive_cost()):
		g.player.prog.refund_passives()
	var sk: Array[String] = _skills()
	for i: int in sk.size():
		if _row(i + 1).has_point(at) and skill_cost(sk[i]) > 0 and g.player.inv.spend("ash", skill_cost(sk[i])):
			g.player.prog.refund_skill(sk[i])
	Audio.sfx("ui_click", -6.0)
