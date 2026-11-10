class_name CharacterPanel
extends GamePanel
## The character sheet (C): every number the game uses for Michael, computed by Stats from level, equipment,
## masteries, attributes and stars. Hover a row for what it does.

const COL_X: Array[float] = [16.0, 196.0]
const COL_W: float = 168.0


## [section, label, value, explanation] rows, from the live stats.
static func rows(m: Michael) -> Array:
	var st: Stats = m.stats
	var rg: Vector2 = st.damage_range()
	var out: Array = [
		["Michael", "Level", "%d" % m.prog.level, "Experience %d / %d" % [roundi(m.prog.xp), roundi(Progression.xp_for(m.prog.level))]],
		["Michael", "Class", m.prog.class_title(), "Masteries: " + ", ".join(m.prog.masteries)],
		["Michael", "Might", "%d" % roundi(st.v("might")), "+2% damage and +3 life per point"],
		["Michael", "Agility", "%d" % roundi(st.v("agility")), "+0.2% crit, +0.6% attack speed, +1% dash recovery per point"],
		["Michael", "Spirit", "%d" % roundi(st.v("spirit")), "+2 glory, +0.06 glory/s, +0.6% holy damage per point"],
		["Offense", "Damage", "%d-%d" % [roundi(rg.x), roundi(rg.y)], "One sword hit at 100% weapon damage, before a critical"],
		["Offense", "Attack speed", "%.2f /s" % st.swings_per_second(), "+%d%% attack speed" % roundi(st.v("attack_pct"))],
		["Offense", "Cast speed", "%.2f s" % st.cast_time(), "+%d%% cast speed: how long Michael stands after a skill" % roundi(st.v("cast_pct"))],
		["Offense", "Critical chance", "%.1f%%" % st.v("crit"), "Chance for a hit to be critical"],
		["Offense", "Critical damage", "+%d%%" % roundi(st.v("crit_damage")), "Extra damage of a critical hit"],
		["Offense", "Holy damage", "+%d%%" % roundi(st.v("holy_pct") + st.v("damage_pct")), "All damage Michael deals"],
		["Offense", "Cooldown recovery", "+%d%%" % roundi(st.v("cooldown_pct")), "Skills come back faster"],
		["Offense", "Life on hit", "%d" % roundi(st.v("life_on_hit")), "Life restored per enemy hit"],
		["Defense", "Life", "%d" % roundi(st.v("life")), ""],
		["Defense", "Life regeneration", "%.1f /s" % st.v("life_regen"), ""],
		["Defense", "Glory", "%d" % roundi(st.v("glory")), "Spent by skills"],
		["Defense", "Glory regeneration", "%.1f /s" % (float(GameData.skills["glory_regen"]) + st.v("glory_regen")), "Plus %d per enemy hit" % int(GameData.skills["glory_on_hit"])],
		["Defense", "Armour", "%d  (-%d%%)" % [roundi(st.v("armour")), roundi(100.0 * st.armour_reduction())], "Reduces damage from blows"],
		["Defense", "Block chance", "%d%%" % roundi(st.v("block")), "Chance to block a blow"],
		["Defense", "Block amount", "%d" % roundi(st.v("block_amount")), "Damage a block takes off"],
		["Defense", "Fire resistance", "%d%%" % roundi(st.v("fire_res")), "Against fire and bursts (max %d%%)" % roundi(Stats.RES_CAP)],
		["Defense", "Shadow resistance", "%d%%" % roundi(st.v("shadow_res")), "Against bolts (max %d%%)" % roundi(Stats.RES_CAP)],
		["Defense", "Dash cooldown", "%.2f s" % m.dash_cooldown(), "Space"],
		["Defense", "Move speed", "%d  (+%d%%)" % [roundi(st.move_speed()), roundi(st.v("move_pct"))], "Pixels per second"],
	]
	return out


func _draw() -> void:
	frame("Character  (C)")
	var tip: Variant = []
	var y: Array[float] = [36.0, 36.0]
	var last: Array[String] = ["", ""]
	for row: Array in rows(m):
		var col: int = 0 if row[0] != "Defense" else 1
		if row[0] != last[col]:
			if last[col] != "":
				y[col] += 6.0
			UiDraw.text(self, Vector2(COL_X[col], y[col]), String(row[0]), UiDraw.GOLD)
			y[col] += UiDraw.LINE + 2.0
			last[col] = row[0]
		var r := Rect2(COL_X[col], y[col] - 10.0, COL_W, 12.0)
		if r.has_point(hover):
			draw_rect(r, Color(1, 1, 1, 0.06))
			if String(row[3]) != "":
				tip = [row[1], row[3]]
		UiDraw.text(self, Vector2(COL_X[col], y[col]), String(row[1]), Color("dcd3c0"))
		UiDraw.text(self, Vector2(COL_X[col], y[col]), String(row[2]), Color.WHITE, UiDraw.BODY, HORIZONTAL_ALIGNMENT_RIGHT, COL_W)
		y[col] += UiDraw.LINE
	UiDraw.tooltip(self, hover, tip, UiDraw.GOLD)
