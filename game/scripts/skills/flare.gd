class_name Flare
extends Skill
## Open the shutters: sunfire around you, sized by your current Light. Tree: area, Oil back per hit, stuns, burn
## Light for a bigger blast, a burning ring, more damage while Blazing, or Lancet (a long cone toward the cursor).

const SPEND_ABOVE: float = 30.0
const LANCET_ARC: float = 0.9
const LANCET_REACH: float = 2.0
const AFTERGLOW_PCT: float = 25.0


func radius() -> float:
	var r: float = maxf(float(data["radius_min"]), p.light.light_radius() * float(data["radius_of_light"]))
	return r * p.stats.area_mult() * (1.0 + val("area_pct") / 100.0)


func use(target: Vector2) -> void:
	var dir: Vector2 = (target - p.global_position).normalized()
	var more: float = 1.0
	if rank("spend") > 0 and p.light.value > SPEND_ABOVE:
		p.light.add(-val("light_cost"))
		more *= 1.0 + spec_more("spend") / 100.0
	var lancet: bool = rank("lancet") > 0
	if lancet:
		more *= 1.0 + spec_more("lancet") / 100.0
	var reach: float = radius() * (LANCET_REACH if lancet else 1.0)
	var at: Vector2 = p.global_position + Vector2(0, -10)
	BurstFx.spawn(fx(), at, reach, dir if lancet else Vector2.ZERO, LANCET_ARC)
	Fx.flash(fx(), at, reach * 1.4, Pal.c("gold"), 1.6, 0.35)
	Fx.halo(fx(), at, reach * 0.6, Pal.c("amber", 0.7), 0.3)
	Audio.sfx("flare", -4.0)
	CameraRig.shake(0.18)
	var hits: Array[Enemy] = enemies_in_arc(p.global_position, dir, reach, rad_to_deg(LANCET_ARC) if lancet else 360.0)
	for e: Enemy in hits:
		Combat.hit_enemy(e, roll(), opts({"dir": e.global_position - p.global_position, "more": more,
			"knockback": float(data["knockback"]), "stun": val("stun"), "blazing_pct": val("blazing_pct")}))
	p.oil = minf(p.stats.max_oil(), p.oil + val("oil_per_hit") * hits.size())
	if rank("afterglow") > 0:
		var avg: Vector2 = base_range()
		BurningGround.spawn(fx(), p.global_position, radius(), val("ring_time"), (avg.x + avg.y) * 0.5 * AFTERGLOW_PCT / 100.0, self)


## A node's per-point "more_pct" (spend and lancet both use the key, so read them apart).
func spec_more(node: String) -> float:
	return float(p.prog.spec_node(id, node)["vals"].get("more_pct", 0.0)) * rank(node)


func info() -> Array:
	var r: Vector2 = shown_range()
	var rows: Array = [["Damage: %d-%d sunfire" % [r.x, r.y], UiDraw.TEXT],
		["Radius now: %d px (%.0f%% of your Light radius)" % [roundi(radius()), float(data["radius_of_light"]) * 100.0], UiDraw.TEXT]]
	if rank("lancet") > 0:
		rows.append(["Lancet: cone %d px long, +%d%% damage" % [roundi(radius() * LANCET_REACH), roundi(spec_more("lancet"))], UiDraw.UP])
	if rank("spend") > 0:
		rows.append(["Spends %d Light for +%d%% (above %d Light)" % [roundi(val("light_cost")), roundi(spec_more("spend")), SPEND_ABOVE], UiDraw.UP])
	return rows
