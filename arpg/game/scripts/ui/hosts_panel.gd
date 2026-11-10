class_name HostsPanel
extends GamePanel
## The Hosts (Isa 40:26): groups of stars. Stars are taken in order within a group with star points
## (one per level, one per answered prayer); a completed group grants its bonus. Some groups need others first.

const CENTER := Vector2(280, 200)
const STAR_HIT: float = 9.0


func _draw() -> void:
	frame("The Hosts  (P)      stars %d" % m.prog.star_points())
	var tip: Variant = []
	var groups: Dictionary = GameData.hosts["groups"]
	var t: float = Time.get_ticks_msec() / 1000.0
	for g: String in groups:
		var grp: Dictionary = groups[g]
		var open: bool = m.prog.group_open(g)
		var taken: int = int(m.prog.stars.get(g, 0))
		var pts: Array = grp["stars"]
		for i: int in range(1, pts.size()):
			draw_line(_pos(pts[i - 1]), _pos(pts[i]), Color(0.98, 0.85, 0.5, 0.8) if i < taken else Color(0.5, 0.5, 0.6, 0.35), 1.0)
		for i: int in pts.size():
			var p: Vector2 = _pos(pts[i])
			if i < taken:
				draw_circle(p, 6.0, Color(1, 0.9, 0.5, 0.25))
				draw_circle(p, 3.0, Color("fbff86"))
			elif i == taken and open:
				draw_circle(p, 3.0, Color(1, 1, 1, 0.6 + 0.4 * sin(t * 4.0)))
			else:
				draw_circle(p, 2.0, Color(0.5, 0.5, 0.6, 0.6 if open else 0.3))
			if p.distance_to(hover) < STAR_HIT:
				tip = _tip(g, i)
		var c: Vector2 = CENTER + SceneData.vec(grp["center"])
		var col: Color = UiDraw.GOLD if m.prog.group_done(g) else (Color.WHITE if open else UiDraw.DIM)
		UiDraw.text(self, c + Vector2(-60, 46), String(grp["name"]), col, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, 120.0)
	var v: PackedStringArray = UiDraw.verse_lines(GameData.hosts["verse"], 80)
	for i: int in v.size():
		UiDraw.text(self, Vector2(0, size.y - 30 + 14 * i), v[i], UiDraw.DIM, UiDraw.BODY, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	UiDraw.tooltip(self, hover, tip, UiDraw.GOLD)


func _pos(star: Dictionary) -> Vector2:
	return CENTER + SceneData.vec(star["pos"])


func _tip(g: String, i: int) -> PackedStringArray:
	var grp: Dictionary = GameData.hosts["groups"][g]
	var lines := PackedStringArray([String(grp["name"]) + "  (star %d of %d)" % [i + 1, grp["stars"].size()]])
	lines.append(_stat_text(grp["stars"][i]["stats"]))
	lines.append("Complete: " + _stat_text(grp["bonus"]))
	if not grp["requires"].is_empty():
		lines.append("Needs: " + ", ".join(grp["requires"].map(func(r: Variant) -> String: return String(GameData.hosts["groups"][r]["name"]))))
	lines.append_array(UiDraw.verse_lines(grp["verse"], 48))
	return lines


static func _stat_text(st: Dictionary) -> String:
	var names: Dictionary = GameData.items["stat_names"]
	var parts: PackedStringArray = []
	for k: String in st:
		if k.ends_with("_more"):
			parts.append("%+d%% %s" % [roundi(float(st[k])), k.trim_suffix("_more")])
		else:
			var fmt: String = names.get(k, k + " %d")
			parts.append(fmt % (float(st[k]) if "%.1f" in fmt else roundi(float(st[k]))))
	return ", ".join(parts)


func clicked(at: Vector2) -> void:
	var groups: Dictionary = GameData.hosts["groups"]
	for g: String in groups:
		var taken: int = int(m.prog.stars.get(g, 0))
		var pts: Array = groups[g]["stars"]
		if taken < pts.size() and _pos(pts[taken]).distance_to(at) < STAR_HIT:
			Audio.sfx("pickup", -10.0, 1.3 if m.prog.take_star(g) else 0.5)
			return
