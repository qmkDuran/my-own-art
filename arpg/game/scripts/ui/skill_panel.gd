class_name SkillPanel
extends GamePanel
## The build: up to two masteries (tabs). Each mastery's bar opens tiers of its skills and adds stats; skill ranks and
## one or two small modifiers per skill; the key a skill sits on (click it to move it). Below: Might, Agility, Spirit.
## The pair of masteries gives a class title. Respec refunds every point.

const TAB_Y: float = 40.0
const BAR := Rect2(20, 76, 280, 10)
const ROW_Y: float = 100.0
const ROW_H: float = 44.0
const ATTR_Y: float = 256.0

var tab: int = 0
var _choosing: bool = false


func _mastery() -> String:
	var ms: Array[String] = m.prog.masteries
	return ms[mini(tab, ms.size() - 1)] if not ms.is_empty() else ""


func _draw() -> void:
	var p: Progression = m.prog
	frame("Skills  (K)      skill points %d   attribute points %d" % [p.skill_points(), p.attribute_points()])
	UiDraw.text(self, Vector2(0, 34), p.class_title(), UiDraw.GOLD, UiDraw.BODY, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14.0)
	var tip: Variant = []
	for i: int in 2:
		var r := _tab_rect(i)
		if i < p.masteries.size():
			var mid: String = p.masteries[i]
			UiDraw.box(self, r, Color(0.25, 0.2, 0.06) if i == tab and not _choosing else Color(0.08, 0.07, 0.11), UiDraw.FRAME)
			UiDraw.text(self, r.position + Vector2(0, 13), String(GameData.skills["masteries"][mid]["name"]), Color.WHITE, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		elif p.can_choose_mastery():
			UiDraw.box(self, r, Color(0.25, 0.2, 0.06) if _choosing else Color(0.12, 0.1, 0.05), UiDraw.GOLD)
			UiDraw.text(self, r.position + Vector2(0, 13), "+ second mastery", UiDraw.GOLD, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		else:
			UiDraw.box(self, r, Color(0.06, 0.06, 0.08), Color(0.25, 0.25, 0.25))
			UiDraw.text(self, r.position + Vector2(0, 13), "level %d" % int(GameData.skills["second_mastery_level"]), UiDraw.DIM, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
	if _choosing:
		tip = _draw_choices()
	else:
		var t: Variant = _draw_mastery(_mastery())
		if not t.is_empty():
			tip = t
	var t2: Variant = _draw_attributes()
	if not t2.is_empty():
		tip = t2
	var rr: Rect2 = _respec_rect()
	UiDraw.box(self, rr, Color(0.12, 0.06, 0.06), Color("b33831"))
	UiDraw.text(self, rr.position + Vector2(0, 13), "Respec", Color.WHITE, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
	if rr.has_point(hover):
		tip = PackedStringArray(["Respec", "Refund every skill and attribute point (masteries stay chosen)."])
	UiDraw.tooltip(self, hover, tip, UiDraw.GOLD)


func _draw_choices() -> Variant:
	var tip: Variant = []
	var i: int = 0
	for mid: String in GameData.skills["masteries"]:
		if m.prog.masteries.has(mid):
			continue
		var r := Rect2(20, ROW_Y + i * 32, 300, 26)
		var md: Dictionary = GameData.skills["masteries"][mid]
		UiDraw.box(self, r, Color(0.2, 0.17, 0.06) if r.has_point(hover) else Color(0.08, 0.07, 0.11), UiDraw.FRAME)
		var names: PackedStringArray = []
		for e: Array in md["skills"]:
			names.append(String(GameData.skill(e[0])["name"]))
		UiDraw.text(self, r.position + Vector2(8, 17), "%s  -  %s" % [md["name"], ", ".join(names)], Color.WHITE)
		if r.has_point(hover):
			tip = UiDraw.verse_lines(md["verse"], 48)
			tip.insert(0, String(md["name"]))
		i += 1
	return tip


func _draw_mastery(mid: String) -> Variant:
	if mid == "":
		return []
	var p: Progression = m.prog
	var md: Dictionary = GameData.skills["masteries"][mid]
	var mx: int = int(GameData.skills["max_mastery"])
	var pts: int = int(p.mastery_points.get(mid, 0))
	UiDraw.text(self, Vector2(20, 72), "%s %d / %d" % [md["name"], pts, mx], UiDraw.GOLD)
	draw_rect(BAR.grow(1.0), UiDraw.INK)
	draw_rect(Rect2(BAR.position, Vector2(BAR.size.x * pts / mx, BAR.size.y)), Color("c78b25"))
	for t: Variant in GameData.skills["tiers"]:
		var x: float = BAR.position.x + BAR.size.x * float(t) / mx
		draw_line(Vector2(x, BAR.position.y - 3), Vector2(x, BAR.end.y + 3), Color("fbff86"), 1.0)
	_plus(_mastery_plus())
	var tip: Variant = []
	if Rect2(BAR.position - Vector2(0, 16), BAR.size + Vector2(0, 18)).has_point(hover):
		var per: PackedStringArray = []
		for k: String in md["per_point"]:
			per.append("%s %s" % [str(md["per_point"][k]), k.replace("_pct", " %").replace("_", " ")])
		tip = PackedStringArray([String(md["name"]) + " mastery", "Per point: " + ", ".join(per),
			"Opens skill tiers at %s points" % ", ".join(GameData.skills["tiers"].map(func(x: Variant) -> String: return str(int(x))))])
		tip.append_array(UiDraw.verse_lines(md["verse"], 48))
	var skills: Array = md["skills"]
	for i: int in skills.size():
		var t: Variant = _row(i, skills[i][0])
		if not t.is_empty():
			tip = t
	return tip


func _row(i: int, id: String) -> Variant:
	var p: Progression = m.prog
	var s: Dictionary = GameData.skill(id)
	var y: float = ROW_Y + i * ROW_H
	var open: bool = p.skill_open(id)
	var icon := Rect2(20, y, 32, 32)
	UiDraw.box(self, icon, Color(0.06, 0.05, 0.09), UiDraw.FRAME if open else Color(0.3, 0.3, 0.3))
	SkillIcons.draw_icon(self, id, icon.get_center(), Color.WHITE if p.rank(id) > 0 else Color(0.45, 0.45, 0.5))
	UiDraw.text(self, Vector2(60, y + 13), String(s["name"]), Color.WHITE if open else UiDraw.DIM)
	var rank_s: String = "%d / %d" % [p.rank(id), int(GameData.skills["max_rank"])] if open \
		else "needs %d" % int(GameData.skills["tiers"][p.tier_of(id)])
	UiDraw.text(self, Vector2(60, y + 28), rank_s, UiDraw.DIM)
	if open:
		_plus(_rank_plus(i))
	var tip: Variant = []
	if Rect2(20, y, 150, 32).has_point(hover):
		tip = SkillInfo.lines(m, id)
	if p.rank(id) > 0 and id != "strike":
		var kr: Rect2 = _key_rect(i)
		var key: String = p.slot_of(id)
		UiDraw.box(self, kr, Color(0.1, 0.1, 0.16), Color("8fd3ff"))
		UiDraw.text(self, kr.position + Vector2(0, 13), key if key != "" else "-", Color("8fd3ff"), UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, kr.size.x)
		if kr.has_point(hover):
			tip = PackedStringArray(["Key: " + (key if key != "" else "none"), "Click to move this skill to the next key."])
	var mods: Array = s["mods"].keys()
	for k: int in mods.size():
		var r: Rect2 = _mod_rect(i, k)
		var taken: bool = p.has_mod(id, mods[k])
		UiDraw.box(self, r, Color(0.35, 0.27, 0.08, 0.9) if taken else Color(0.08, 0.07, 0.11), UiDraw.GOLD if taken else Color(0.35, 0.32, 0.26))
		UiDraw.text(self, r.position + Vector2(0, 13), String(s["mods"][mods[k]]["name"]), Color.WHITE if taken else UiDraw.DIM,
			UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)
		if r.has_point(hover):
			tip = PackedStringArray([s["mods"][mods[k]]["name"], s["mods"][mods[k]]["desc"], "Costs 1 point; needs rank 1"])
	return tip


func _draw_attributes() -> Variant:
	var tip: Variant = []
	var attr: Dictionary = GameData.skills["attributes"]
	var i: int = 0
	for a: String in attr:
		var y: float = ATTR_Y + i * 24
		var total: float = m.stats.v(a)
		UiDraw.text(self, Vector2(20, y + 13), "%s  %d" % [attr[a]["name"], roundi(total)], Color.WHITE)
		_plus(_attr_plus(i), m.prog.attribute_points() > 0)
		if Rect2(20, y, 160, 20).has_point(hover):
			var per: PackedStringArray = []
			for k: String in attr[a]["per_point"]:
				per.append("%s %s" % [str(attr[a]["per_point"][k]), k.replace("_pct", " %").replace("_", " ")])
			tip = PackedStringArray([String(attr[a]["name"]), "Per point: " + ", ".join(per)])
		i += 1
	return tip


func _plus(r: Rect2, can: bool = true) -> void:
	can = can and (m.prog.skill_points() > 0 or r.position.y >= ATTR_Y)
	UiDraw.box(self, r, Color(0.2, 0.16, 0.05) if can else Color(0.08, 0.08, 0.1), UiDraw.GOLD if can else Color(0.3, 0.3, 0.3))
	UiDraw.text(self, r.position + Vector2(0, 13), "+", Color.WHITE if can else UiDraw.DIM, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, r.size.x)


func _tab_rect(i: int) -> Rect2:
	return Rect2(20 + i * 150, TAB_Y, 140, 20)


func _mastery_plus() -> Rect2:
	return Rect2(310, 70, 18, 18)


func _rank_plus(i: int) -> Rect2:
	return Rect2(150, ROW_Y + i * ROW_H + 7, 18, 18)


func _key_rect(i: int) -> Rect2:
	return Rect2(174, ROW_Y + i * ROW_H + 7, 34, 18)


func _mod_rect(i: int, k: int) -> Rect2:
	return Rect2(214 + k * 104, ROW_Y + i * ROW_H + 7, 98, 18)


func _attr_plus(i: int) -> Rect2:
	return Rect2(150, ATTR_Y + i * 24 + 1, 18, 18)


func _respec_rect() -> Rect2:
	return Rect2(size.x - 90, size.y - 30, 76, 20)


func clicked(at: Vector2) -> void:
	var p: Progression = m.prog
	for i: int in 2:
		if _tab_rect(i).has_point(at):
			if i < p.masteries.size():
				tab = i
				_choosing = false
			elif p.can_choose_mastery():
				_choosing = true
			return
	if _respec_rect().has_point(at):
		p.respec()
		_feedback(true)
		return
	var ai: int = 0
	for a: String in GameData.skills["attributes"]:
		if _attr_plus(ai).has_point(at):
			_feedback(p.add_attribute(a))
			return
		ai += 1
	if _choosing:
		var i: int = 0
		for mid: String in GameData.skills["masteries"]:
			if p.masteries.has(mid):
				continue
			if Rect2(20, ROW_Y + i * 32, 300, 26).has_point(at):
				_feedback(p.choose_mastery(mid))
				_choosing = false
				tab = p.masteries.size() - 1
				return
			i += 1
		return
	var mid2: String = _mastery()
	if _mastery_plus().has_point(at):
		_feedback(p.add_mastery(mid2))
		return
	var skills: Array = GameData.skills["masteries"][mid2]["skills"]
	for i: int in skills.size():
		var id: String = skills[i][0]
		if _rank_plus(i).has_point(at):
			_feedback(p.add_rank(id))
			return
		if _key_rect(i).has_point(at) and p.rank(id) > 0 and id != "strike":
			p.cycle_slot(id)
			_feedback(true)
			return
		var mods: Array = GameData.skill(id)["mods"].keys()
		for k: int in mods.size():
			if _mod_rect(i, k).has_point(at):
				_feedback(p.add_mod(id, mods[k]))
				return


func _feedback(ok: bool) -> void:
	Audio.sfx("pickup", -10.0, 1.2 if ok else 0.5)
