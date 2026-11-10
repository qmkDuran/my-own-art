class_name SkillInfo
extends RefCounted
## Tooltip lines for a skill with the real numbers the game uses now: damage range at the current rank (and the next),
## area, durations, glory cost and cooldown after cooldown recovery, the modifiers (taken or not) and the verse.

const NUMBERS: Dictionary = {  # data key -> [label, unit]
	"radius": ["Radius", "px"], "range": ["Reach", "px"], "length": ["Length", "px"], "arc": ["Arc", "deg"],
	"fear": ["Fear", "s"], "stun": ["Stun", "s"], "silence": ["Silence (casters)", "s"], "duration": ["Lasts", "s"],
	"push": ["Knockback", ""], "distance": ["Distance", "px"], "time": ["Time (untouchable)", "s"],
}


static func lines(m: Michael, id: String) -> Array:
	var s: Dictionary = GameData.skill(id)
	var out: Array = [String(s["name"]), [String(s["desc"]), Color("dcd3c0")]]
	var r: int = m.prog.rank(id)
	if id != "dash":
		out.append(["Rank %d / %d" % [r, int(GameData.skills["max_rank"])], UiDraw.DIM])
	var mult_now: float = m.prog.rank_mult(id)
	var mult_next: float = 1.0 + float(GameData.skills["rank_bonus"]) * float(r)
	if s.has("damage"):
		var dmg: Variant = s["damage"]
		var parts: PackedStringArray = []
		for d: Variant in (dmg if dmg is Array else [dmg]):
			var rg: Vector2 = m.stats.damage_range(float(d) * mult_now)
			parts.append("%d-%d" % [roundi(rg.x), roundi(rg.y)])
		out.append("Damage %s  (%s weapon)" % [" / ".join(parts), _pct(dmg)])
		if r > 0 and r < int(GameData.skills["max_rank"]):
			var d0: float = float(dmg[0] if dmg is Array else dmg)
			var nx: Vector2 = m.stats.damage_range(d0 * mult_next)
			out.append(["Next rank %d-%d" % [roundi(nx.x), roundi(nx.y)], UiDraw.UP])
	if s.has("dps"):
		var rg: Vector2 = m.stats.damage_range(float(s["dps"]) * mult_now)
		out.append("Burns %d-%d per second" % [roundi(rg.x), roundi(rg.y)])
	if s.has("reduce"):
		out.append("Blows weakened by %d%%" % roundi(100.0 * m.skills.shield_reduce()))
	if s.has("heal"):
		out.append("Mends %.1f%% life per second; drains %.1f glory per second" % [100.0 * float(s["heal"]), float(s["upkeep"])])
	for k: String in NUMBERS:
		if s.has(k):
			out.append("%s %s %s" % [NUMBERS[k][0], str(s[k]), NUMBERS[k][1]])
	if id == "dash":
		out.append("Cooldown %.2fs" % m.dash_cooldown())
	else:
		out.append("Glory %d   Cooldown %.1fs" % [int(s["cost"]), m.stats.cooldown(float(s["cooldown"]))])
	for mod: String in s.get("mods", {}):
		var taken: bool = m.prog.has_mod(id, mod)
		out.append([("+ " if taken else "- ") + "%s: %s" % [s["mods"][mod]["name"], s["mods"][mod]["desc"]], UiDraw.UP if taken else UiDraw.DIM])
	for v: String in UiDraw.verse_lines(String(s["verse"]), 52):
		out.append([v, UiDraw.DIM])
	return out


static func _pct(dmg: Variant) -> String:
	var parts: PackedStringArray = []
	for d: Variant in (dmg if dmg is Array else [dmg]):
		parts.append("%d%%" % roundi(float(d) * 100.0))
	return " / ".join(parts)
