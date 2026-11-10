class_name SkillPanel
extends GamePanel
## The mastery: points into the bar open higher tiers of skills and add life and damage; points into a skill raise
## its rank; each skill has two small modifiers that cost a point each.

const ROW_Y: float = 92.0
const ROW_H: float = 48.0
const BAR := Rect2(20, 44, 300, 10)


func _draw() -> void:
	frame("Skills  (K)      points %d" % m.prog.skill_points())
	var md: Dictionary = GameData.skills["mastery"]
	var mx: int = int(md["max"])
	UiDraw.text(self, Vector2(20, 40), "%s %d / %d" % [md["name"], m.prog.mastery, mx], UiDraw.GOLD)
	draw_rect(BAR.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(BAR.position, Vector2(BAR.size.x * m.prog.mastery / mx, BAR.size.y)), Color("c78b25"))
	for t: Variant in md["tiers"]:
		var x: float = BAR.position.x + BAR.size.x * float(t) / mx
		draw_line(Vector2(x, BAR.position.y - 3), Vector2(x, BAR.end.y + 3), Color("fbff86"), 1.0)
	_plus(_mastery_plus())
	var tip := PackedStringArray()
	if Rect2(BAR.position - Vector2(0, 16), BAR.size + Vector2(0, 18)).has_point(hover):
		tip = PackedStringArray(["%s: +%d life, +%.1f damage per point" % [md["name"], int(md["per_point"]["life"]),
			float(md["per_point"]["damage"])], "Opens tiers at %s points" % ", ".join(md["tiers"].map(func(x: Variant) -> String: return str(int(x))))])
		tip.append_array(UiDraw.verse_lines(md["verse"], 48))
	var ids: Array = GameData.skills["slots"]
	for i: int in ids.size():
		var t: PackedStringArray = _row(i, ids[i])
		if not t.is_empty():
			tip = t
	UiDraw.tooltip(self, hover, tip, UiDraw.GOLD)


func _row(i: int, id: String) -> PackedStringArray:
	var s: Dictionary = GameData.skill(id)
	var y: float = ROW_Y + i * ROW_H
	var open: bool = m.prog.tier_open(int(s["tier"]))
	var icon := Rect2(20, y, 34, 34)
	UiDraw.box(self, icon, Color(0.06, 0.05, 0.09), UiDraw.FRAME if open else Color(0.3, 0.3, 0.3))
	SkillIcons.draw_icon(self, id, icon.get_center(), Color.WHITE if m.prog.rank(id) > 0 else Color(0.45, 0.45, 0.5))
	UiDraw.text(self, Vector2(62, y + 13), String(s["name"]), Color.WHITE if open else UiDraw.DIM)
	var rank_s: String = "%d / %d" % [m.prog.rank(id), int(GameData.skills["max_rank"])] if open \
		else "needs mastery %d" % int(GameData.skills["mastery"]["tiers"][int(s["tier"])])
	UiDraw.text(self, Vector2(62, y + 29), rank_s, UiDraw.DIM)
	if open:
		_plus(_rank_plus(i))
	var tip := PackedStringArray()
	if Rect2(20, y, 200, 34).has_point(hover):
		tip = PackedStringArray([s["name"], s["desc"], "Glory %d   Cooldown %.1fs   Key %s" % [int(s["cost"]), float(s["cooldown"]), s["key"]]])
		tip.append_array(UiDraw.verse_lines(s["verse"], 48))
	var mods: Array = s["mods"].keys()
	for k: int in mods.size():
		var r: Rect2 = _mod_rect(i, k)
		var taken: bool = m.prog.has_mod(id, mods[k])
		UiDraw.box(self, r, Color(0.35, 0.27, 0.08, 0.9) if taken else Color(0.08, 0.07, 0.11), UiDraw.GOLD if taken else Color(0.35, 0.32, 0.26))
		UiDraw.text(self, r.position + Vector2(0, 13), String(s["mods"][mods[k]]["name"]), Color.WHITE if taken else UiDraw.DIM,
			16, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if r.has_point(hover):
			tip = PackedStringArray([s["mods"][mods[k]]["name"], s["mods"][mods[k]]["desc"], "Costs 1 point; needs rank 1"])
	return tip


func _plus(r: Rect2) -> void:
	var can: bool = m.prog.skill_points() > 0
	UiDraw.box(self, r, Color(0.2, 0.16, 0.05) if can else Color(0.08, 0.08, 0.1), UiDraw.GOLD if can else Color(0.3, 0.3, 0.3))
	UiDraw.text(self, r.position + Vector2(0, 13), "+", Color.WHITE if can else UiDraw.DIM, 16, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _mastery_plus() -> Rect2:
	return Rect2(330, 38, 18, 18)


func _rank_plus(i: int) -> Rect2:
	return Rect2(186, ROW_Y + i * ROW_H + 8, 18, 18)


func _mod_rect(i: int, k: int) -> Rect2:
	return Rect2(214 + k * 100, ROW_Y + i * ROW_H + 8, 94, 18)


func clicked(at: Vector2) -> void:
	if _mastery_plus().has_point(at):
		_feedback(m.prog.add_mastery())
		return
	var ids: Array = GameData.skills["slots"]
	for i: int in ids.size():
		if _rank_plus(i).has_point(at):
			_feedback(m.prog.add_rank(ids[i]))
			return
		var mods: Array = GameData.skill(ids[i])["mods"].keys()
		for k: int in mods.size():
			if _mod_rect(i, k).has_point(at):
				_feedback(m.prog.add_mod(ids[i], mods[k]))
				return


func _feedback(ok: bool) -> void:
	Audio.sfx("pickup", -10.0, 1.2 if ok else 0.5)
