class_name CharacterPanel
extends GamePanel
## Every number that matters, straight from Stats (the same values combat uses), grouped: you, offence, defence,
## Light and Oil. Hover a row: what it does, and what a little more of it would do to your real numbers
## (Derived), so no percentage stands alone.

const ROW: float = 13.0
const COL_X: float = 12.0
const VAL_W: float = 120.0
const TOP_Y: float = 44.0


## [label, value, stat key (or ""), probe amount] rows; [section] rows are headings.
static func rows(p: Player) -> Array:
	var st: Stats = p.stats
	var dv: Dictionary = Derived.of(st, p)
	var hit: Vector2 = dv["bolt"]
	var mast: String = String(GameData.passives["trees"][p.prog.mastery]["name"]) if p.prog.mastery != "" else "(choose at level %d)" % int(GameData.player["mastery_level"])
	return [
		["Lamplighter"], ["Level", "%d" % p.prog.level, "", 0.0], ["Mastery", mast, "", 0.0],
		["Offence"], ["Wickbolt hit", "%d-%d" % [roundi(hit.x), roundi(hit.y)], "", 0.0],
		["Wickbolt damage per second", "%.1f" % float(dv["dps"]), "", 0.0],
		["Staff damage", "%d-%d" % [roundi(st.staff_range().x), roundi(st.staff_range().y)], "staff_damage_pct", 10.0],
		["Attack speed", "%+d%%" % roundi(st.v("attack_speed_pct")), "attack_speed_pct", 5.0],
		["Cast speed", "%+d%%" % roundi(st.v("cast_speed_pct")), "cast_speed_pct", 5.0],
		["Critical chance", "%.1f%%" % st.crit_chance(), "crit_chance", 2.0],
		["Critical multiplier", "%d%%" % roundi(st.crit_multi()), "crit_multi", 10.0],
		["Increased sunfire", "%+d%%" % roundi(st.v("sunfire_pct") + st.v("damage_pct")), "sunfire_pct", 5.0],
		["Increased spell damage", "%+d%%" % roundi(st.v("spell_pct")), "spell_pct", 5.0],
		["vs Shrouded enemies", "%+d%%" % roundi(st.v("damage_vs_shrouded_pct")), "damage_vs_shrouded_pct", 10.0],
		["Ignite chance", "%d%%" % roundi(st.v("burn_chance")), "burn_chance", 5.0],
		["Defence"], ["Life", "%d" % roundi(st.max_life()), "life", 10.0],
		["Life regeneration", "%.1f /s" % st.life_regen(), "life_regen", 1.0],
		["Armour", "%d  (stops %.1f%% of a 20 hit)" % [roundi(st.armour()), float(dv["armour"])], "armour", 20.0],
		["Dusk resistance", "%d%%" % roundi(st.dusk_res()), "dusk_res", 5.0],
		["Movement speed", "%d px/s" % roundi(st.move_speed()), "move_pct", 5.0],
		["Light and Oil"], ["Light", "%d  (radius %d px)" % [roundi(p.light.value), roundi(p.light.light_radius())], "", 0.0],
		["Light radius", "%+d%%" % roundi(st.v("light_radius_pct")), "light_radius_pct", 10.0],
		["Light on kill", "+%.1f" % (float(GameData.light["kill_gain"]) + st.v("light_on_kill")), "light_on_kill", 1.0],
		["Light lost when hit", "-%d%%" % roundi(minf(90.0, st.v("light_loss_reduction"))), "light_loss_reduction", 10.0],
		["Oil", "%d  (+%.1f /s)" % [roundi(st.max_oil()), st.oil_regen()], "oil", 10.0], ["Tonics", "%d" % p.max_tonics(), "", 0.0],
	]


## What a stat row means, in real numbers.
static func row_tip(p: Player, row: Array) -> Array:
	var out: Array = [String(row[0]), [String(row[1]), UiDraw.GOLD]]
	var key: String = String(row[2])
	if key == "":
		return out
	out.append([String(GameData.stats.get(key, {}).get("desc", "")), UiDraw.TEXT])
	var now: Dictionary = Derived.of(p.stats, p)
	var more: Array = Derived.changes(now, Derived.of(Derived.with_stat(p, key, float(row[3])), p))
	if not more.is_empty():
		out.append(["With %s more:" % GameData.stat_line(key, float(row[3])), UiDraw.DIM])
		out.append_array(more)
	return out


func _content() -> void:
	var y: float = TOP_Y
	for row: Array in rows(g.player):
		if row.size() == 1:
			y += 4.0
			UiDraw.text(self, Vector2(COL_X, y), String(row[0]), UiDraw.GOLD)
			draw_line(Vector2(COL_X, y + 3.0), Vector2(size.x - COL_X, y + 3.0), Color(UiDraw.FRAME, 0.5))
		else:
			UiDraw.text(self, Vector2(COL_X + 6.0, y), String(row[0]), UiDraw.DIM)
			UiDraw.text(self, Vector2(size.x - COL_X - VAL_W, y), String(row[1]), UiDraw.TEXT, UiDraw.BODY, HORIZONTAL_ALIGNMENT_RIGHT, VAL_W)
		y += ROW


func _hover(at: Vector2) -> void:
	var y: float = TOP_Y
	for row: Array in rows(g.player):
		if row.size() == 1:
			y += 4.0
		elif Rect2(COL_X, y - ROW + 3.0, size.x - COL_X * 2.0, ROW).has_point(at):
			tip(row_tip(g.player, row))
			return
		y += ROW
