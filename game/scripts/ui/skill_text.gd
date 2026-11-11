class_name SkillText
extends RefCounted
## Tooltip rows for skills and their specialisation nodes, all numbers from the live Skill objects.

const TAG := Color("c9b98f")
const WRAP: float = 250.0


static func rows(ci: CanvasItem, p: Player, id: String) -> Array:
	var d: Dictionary = GameData.skill(id)
	var out: Array = [String(d["name"]), [", ".join(PackedStringArray(d["tags"])), TAG]]
	for line: String in UiDraw.wrap(ci, String(d["desc"]), WRAP):
		out.append([line, UiDraw.DIM])
	var s: Skill = p.skills.skill(id)
	if s == null:
		if id == "dash":
			var cd: Vector2 = p.dash_cooldown()
			out.append(["Distance %d px, cooldown %.1f s, untouchable while dashing" % [roundi(float(GameData.player["dash"]["distance"])), cd.y], UiDraw.TEXT])
		return out
	out.append(["Level %d   (%d specialisation points free)" % [p.prog.skill_level(id), p.prog.spec_points(id)], UiDraw.GOLD])
	var cost: String = "no cost" if p.skills.cost_of(id) <= 0.0 else "%d Oil" % roundi(p.skills.cost_of(id))
	out.append(["%s   cooldown %.1f s   %s %.2f s" % [cost, s.cooldown(), "cast" if s.is_spell() else "attack", s.cast_time()], UiDraw.TEXT])
	out.append_array(s.info())
	return out


static func node_rows(ci: CanvasItem, p: Player, id: String, node: Dictionary) -> Array:
	var r: int = p.prog.node_rank(id, String(node["id"]))
	var out: Array = [String(node["name"]), ["Points %d / %d" % [r, int(node["max"])], UiDraw.GOLD]]
	for line: String in UiDraw.wrap(ci, String(node["text"]), WRAP):
		out.append([line, UiDraw.TEXT])
	var block: String = p.prog.spec_block(id, String(node["id"]))
	if block != "" and block != "Maxed":
		out.append([block, UiDraw.DOWN])
	out.append(["Click: add a point   Right-click: refund", UiDraw.DIM])
	return out
