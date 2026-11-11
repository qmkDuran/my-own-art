class_name Combat
extends RefCounted
## Damage, both ways. The Lamplighter's hits: base x increased x Blazing x Shrouded (outside every light enemies
## take less, unless you build for it) x exposure x crit. Enemies' hits: base x level x rank x Shrouded bonus,
## less armour (blunt) or Dusk resistance (dusk); every hit dims the lantern.

const KILL_SHAKE: float = 0.14


## Deal `base` damage to `e`. opts: kind ("attack"/"spell"), dir, more (multiplier), vs_shrouded_pct, knockback,
## stun, burn_chance, dot (a burn tick: no crit, no sparks), heavy (hit-stop), skill.
static func hit_enemy(e: Enemy, base: float, opts: Dictionary = {}) -> void:
	if e == null or not is_instance_valid(e) or e.dead:
		return
	var g: Game = Game.current
	var st: Stats = g.player.stats
	var L: Dictionary = GameData.light
	var dot: bool = bool(opts.get("dot", false))
	var kin: Kindle = g.player.skills.skill("kindle") as Kindle
	if not dot:
		base += kin.added()
	var dmg: float = base * st.increased(String(opts.get("kind", "attack"))) * float(opts.get("more", 1.0))
	if g.player.light.state() == "blazing":
		dmg *= 1.0 + (float(L["blazing_damage_pct"]) + st.v("blazing_pct") + float(opts.get("blazing_pct", 0.0))) / 100.0
	var ecl: Eclipse = g.player.skills.skill("eclipse") as Eclipse
	if e.shrouded:
		dmg *= float(L["shrouded_damage_taken_mult"]) * (1.0 + (st.v("damage_vs_shrouded_pct") + float(opts.get("vs_shrouded_pct", 0.0))
			+ ecl.vs_shrouded_pct()) / 100.0)
	dmg *= e.damage_taken_mult()
	var crit: bool = not dot and randf() * 100.0 < st.crit_chance()
	if crit:
		dmg *= st.crit_multi() / 100.0
	dmg = maxf(1.0, roundf(dmg))
	if Dev.one_hit:
		dmg = e.life
	CombatLog.add("%s %d%s -> %s" % [String(opts.get("skill", "hit")), dmg, " crit" if crit else "", e.kind])
	var dir: Vector2 = opts.get("dir", Vector2.ZERO)
	e.take_damage(dmg, crit, dir, opts)
	g.player.gain_life(dmg * ecl.leech())
	FloatText.hit(e, dmg, crit, dot)
	if dot:
		return
	var share: float = dmg / maxf(e.max_life, 1.0)
	var col: Color = Pal.c("gold") if String(opts.get("kind", "attack")) == "attack" else Pal.c("amber")
	var k: float = share * (1.5 if bool(opts.get("heavy", false)) else 1.0)
	Impact.hit(e.global_position + Vector2(0, -e.body_height() * 0.5), dir, k, col, crit, e.dead)
	Audio.sfx("impact", -4.0 + 4.0 * minf(share * 3.0, 1.0), randf_range(0.9, 1.1))
	Audio.sfx("hurt_" + _family(e), -9.0, randf_range(0.9, 1.15))
	if randf() * 100.0 < float(opts.get("burn_chance", 0.0)) + st.v("burn_chance") + kin.burn_chance():
		e.ignite(dmg * 0.6)


## Which hurt sound a creature makes.
static func _family(e: Enemy) -> String:
	return {"gloam": "dark", "moth": "moth", "crawler": "moth", "hound": "beast", "husk": "beast", "heron": "beast"}.get(e.kind, "glass")


## An enemy (or its shard) hits the Lamplighter.
static func hit_player(src: Enemy, base: float, type: String, at: Vector2) -> void:
	var g: Game = Game.current
	var p: Player = g.player
	if p.untouchable():
		return
	var dmg: float = base
	var alive: bool = is_instance_valid(src)
	if alive and src.shrouded:
		dmg *= float(GameData.light["shrouded_damage_dealt_mult"])
	if type == "blunt":
		dmg *= 1.0 - p.stats.armour_reduction(dmg)
	else:
		dmg *= 1.0 - p.stats.dusk_res() / 100.0
	dmg = maxf(1.0, roundf(dmg))
	var drain: float = src.light_drain() if alive else 0.0
	dmg = (p.skills.skill("glass_ward") as GlassWard).absorb(dmg)
	if alive:
		(p.skills.skill("kindle") as Kindle).struck_by(src)
	CombatLog.add("%s %d %s -> Lamplighter (life %d)" % [src.kind if alive else "shot", dmg, type, p.life - dmg])
	p.take_hit(dmg, at, drain)
	FloatText.hit(p, dmg, false, false, Pal.c("rose"))
