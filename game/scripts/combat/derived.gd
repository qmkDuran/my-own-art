class_name Derived
extends RefCounted
## The numbers a player feels, worked out from a Stats: Wickbolt's hit, its damage per second, life, how much of a
## 20-damage blow armour stops, Dusk resistance, speed, Light radius, Oil. Comparing two Stats (now and with a
## change: one more point of a stat, a different item worn) gives tooltips in real numbers, not bare percentages.

const PROBE_HIT: float = 20.0
const KEYS: Array = [["bolt", "Wickbolt hit"], ["dps", "Wickbolt damage per second"], ["life", "Life"],
	["armour", "Armour stops (of a 20 hit)"], ["res", "Dusk resistance"], ["move", "Movement"], ["light", "Light radius"],
	["oil", "Oil"]]


static func of(st: Stats, p: Player) -> Dictionary:
	var wb: Skill = p.skills.skill("wickbolt")
	var hit: Vector2 = st.staff_range() * float(wb.data["damage_pct"]) / 100.0 * st.increased("attack")
	var cast: float = float(wb.data["time"]) / (st.attack_speed_mult() * (1.0 + wb.val("speed_pct") / 100.0))
	var crit: float = 1.0 + clampf(st.crit_chance(), 0.0, 100.0) / 100.0 * (st.crit_multi() / 100.0 - 1.0)
	return {"bolt": hit, "dps": (hit.x + hit.y) * 0.5 * crit / maxf(cast, 0.05), "life": st.max_life(),
		"armour": st.armour_reduction(PROBE_HIT) * 100.0, "res": st.dusk_res(), "move": st.move_speed(),
		"light": p.light.target_radius() * st.light_radius_mult() / maxf(p.stats.light_radius_mult(), 0.01), "oil": st.max_oil()}


## Stats as they would be with `item` worn in `slot` (or the slot emptied with {}).
static func with_item(p: Player, slot: String, item: Dictionary) -> Stats:
	var inv := Inventory.new()
	inv.equipped = p.inv.equipped.duplicate()
	inv.equipped[slot] = item
	var st := Stats.new()
	st.rebuild(p.prog, inv)
	return st


## Stats as they would be with `delta` more of one stat.
static func with_stat(p: Player, key: String, delta: float) -> Stats:
	return with_stats(p, {key: delta})


## Stats as they would be with every stat in `deltas` raised by its amount (one more passive point, say).
static func with_stats(p: Player, deltas: Dictionary) -> Stats:
	var st := Stats.new()
	st.rebuild(p.prog, p.inv)
	for k: String in deltas:
		st.total[k] = float(st.total.get(k, 0.0)) + float(deltas[k])
	return st


## Tooltip rows for what changes between two sets of numbers (green up, red down); empty if nothing does.
static func changes(before: Dictionary, after: Dictionary) -> Array:
	var out: Array = []
	for k: Array in KEYS:
		var id: String = k[0]
		if id == "bolt":
			var a: Vector2 = before[id]
			var b: Vector2 = after[id]
			if b.distance_to(a) >= 0.5:
				out.append(["%s %d-%d (now %d-%d)" % [k[1], roundi(b.x), roundi(b.y), roundi(a.x), roundi(a.y)], UiDraw.UP if b.x + b.y > a.x + a.y else UiDraw.DOWN])
			continue
		var d: float = float(after[id]) - float(before[id])
		if absf(d) >= 0.05:
			out.append(["%s %s (%s%s)" % [k[1], _fmt(id, float(after[id])), "+" if d > 0.0 else "-", _fmt(id, absf(d))], UiDraw.UP if d > 0.0 else UiDraw.DOWN])
	return out


static func _fmt(id: String, v: float) -> String:
	match id:
		"armour", "res":
			return "%.1f%%" % v
		"move":
			return "%d px/s" % roundi(v)
		"light":
			return "%d px" % roundi(v)
		"dps":
			return "%.1f" % v
	return "%d" % roundi(v)
