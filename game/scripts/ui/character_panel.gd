class_name CharacterPanel
extends GamePanel
## Every number that matters, straight from Stats (the same values combat uses). Grouped: who you are, offence,
## defence, light. Hover a row for what it means.

const ROW: float = 13.0
const COL_X: float = 12.0
const VAL_W: float = 120.0
const TOP_Y: float = 44.0


## [label, value, colour] rows; [section] rows are headings.
static func rows(p: Player) -> Array:
	var st: Stats = p.stats
	var sun: Skill = p.skills.skill("wickbolt")
	var r: Vector2 = sun.shown_range(100.0)
	var mast: String = String(GameData.passives["trees"][p.prog.mastery]["name"]) if p.prog.mastery != "" else "(choose at level %d)" % int(GameData.player["mastery_level"])
	return [
		["Lamplighter"], ["Level", "%d" % p.prog.level], ["Mastery", mast],
		["Offence"], ["Staff damage", "%d-%d" % [roundi(st.staff_range().x), roundi(st.staff_range().y)]],
		["Wickbolt per hit", "%d-%d" % [r.x, r.y]], ["Attack speed", "%+d%%" % roundi(st.v("attack_speed_pct"))],
		["Cast speed", "%+d%%" % roundi(st.v("cast_speed_pct"))], ["Critical chance", "%.1f%%" % st.crit_chance()],
		["Critical multiplier", "%d%%" % roundi(st.crit_multi())], ["Increased sunfire", "%+d%%" % roundi(st.v("sunfire_pct") + st.v("damage_pct"))],
		["Increased spell damage", "%+d%%" % roundi(st.v("spell_pct"))], ["vs Shrouded enemies", "%+d%%" % roundi(st.v("damage_vs_shrouded_pct"))],
		["Ignite chance", "%d%%" % roundi(st.v("burn_chance"))],
		["Defence"], ["Life", "%d" % roundi(st.max_life())], ["Life regeneration", "%.1f /s" % st.life_regen()],
		["Armour", "%d  (stops %d%% of a 20 hit)" % [roundi(st.armour()), roundi(st.armour_reduction(20.0) * 100.0)]],
		["Dusk resistance", "%d%%" % roundi(st.dusk_res())], ["Movement speed", "%d px/s" % roundi(st.move_speed())],
		["Light and Oil"], ["Light", "%d  (radius %d px)" % [roundi(p.light.value), roundi(p.light.light_radius())]],
		["Light radius", "%+d%%" % roundi(st.v("light_radius_pct"))], ["Light on kill", "+%.1f" % (float(GameData.light["kill_gain"]) + st.v("light_on_kill"))],
		["Light lost when hit", "-%d%%" % roundi(minf(90.0, st.v("light_loss_reduction")))],
		["Oil", "%d  (+%.1f /s)" % [roundi(st.max_oil()), st.oil_regen()]], ["Tonics", "%d" % p.max_tonics()],
	]


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
