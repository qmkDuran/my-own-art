class_name TerrainRules
extends RefCounted
## What the ground under a creature does in an arena (tamer.json "terrain"), and what moves do to the ground:
## water and mud slow, tall grass hides at range (attacking reveals), the ledge gives range and damage, walls,
## thorns and ledge edges punish knockback, coals burn. Each species is stronger on its home terrain (never weaker
## anywhere). Moves burn grass and vines (Ember), flatten grass and clear fog (Gale), shatter rocks and reveal
## (Echo), and heavy hits break rocks, bridges and cracked floor. Outside an arena everything is neutral.

const F := ArenaLayout.F


static func arena() -> Arena:
	var g: TamerGame = TamerGame.current
	return g.arena if g != null and g.area == "arena" else null


static func T() -> Dictionary:
	return TamerData.rule("terrain")


static func feature_at(p: Vector2) -> int:
	var a: Arena = arena()
	return a.layout.f_at(p) if a != null else F.NONE


static func feature_name(f: int) -> String:
	for k: String in ArenaLayout.NAMES:
		if int(ArenaLayout.NAMES[k]) == f:
			return k
	return "none"


## The species' home terrain bonus, if it stands in it ({} otherwise).
static func home(c: Creature) -> Dictionary:
	var h: Dictionary = c.rec.data().get("home", {})
	if h.is_empty() or arena() == null:
		return {}
	return h if (h["terrain"] as Array).has(feature_name(feature_at(c.global_position))) else {}


static func speed_mult(c: Creature) -> float:
	var k: float = float(home(c).get("speed", 1.0))
	match feature_at(c.global_position):
		F.SHALLOW:
			k *= float(T()["shallow_speed"])
		F.MUD:
			k *= float(T()["mud_speed"])
		F.BURNT:
			k *= float(T()["burnt_speed"])
		F.PIT:
			k *= float(T()["pit_speed"])
	return k


static func dealt_mult(c: Creature) -> float:
	var k: float = float(home(c).get("dealt", 1.0))
	if feature_at(c.global_position) == F.LEDGE:
		k *= float(T()["ledge_dealt"])
	return k


static func taken_mult(c: Creature) -> float:
	return float(home(c).get("taken", 1.0))


static func range_mult(c: Creature) -> float:
	var k: float = float(home(c).get("range", 1.0))
	if feature_at(c.global_position) == F.LEDGE:
		k *= float(T()["ledge_range"])
	return k


## Can `observer` see `c`? Smoke hides it; tall grass (or a home that hides it) and fog hide it at range until it
## attacks.
static func hidden_from(c: Creature, observer: Node2D) -> bool:
	if c.effects.flag("hidden"):
		return true
	if arena() == null:
		return false
	if feature_at(c.global_position) == F.ASH:
		return true                                        # smoke hides even someone who just attacked
	if c.reveal_t > 0.0:
		return false
	var d: float = observer.global_position.distance_to(c.global_position)
	if arena().fog != null and d > float(T()["fog_vision"]) and not arena().fog.cleared_at(c.global_position):
		return true
	var in_cover: bool = feature_at(c.global_position) == F.GRASS or bool(home(c).get("hidden", false))
	return in_cover and d > float(T()["grass_hide_range"])


## Every frame in an arena: fire burns whoever stands in it, the one who lit it too (except an Ember creature at
## home in it); a Rot creature heals in its mud.
static func tick(c: Creature, delta: float) -> void:
	if arena() == null:
		return
	if feature_at(c.global_position) == F.COALS and not bool(home(c).get("burn_immune", false)):
		c.rec.life -= c.rec.max_life() * float(T()["coals_dps"]) * delta
		if c.rec.life <= 0.0:
			c.faint()
	var regen: float = float(home(c).get("regen", 0.0))
	if regen > 0.0:
		c.rec.heal_points(c.rec.max_life() * regen / 100.0 * delta)


## After a shove: slammed into a wall (extra stagger), knocked into thorns (damage), off the ledge (a fall).
static func after_knock(c: Creature, dir: Vector2, from: Vector2) -> void:
	var a: Arena = arena()
	if a == null or dir == Vector2.ZERO:
		return
	var ahead: int = a.layout.f_at(c.global_position + dir.normalized() * (c.hit_radius() + 6.0))
	if ahead == F.WALL or ahead == F.ROCK or ahead == F.TREE:
		c.stagger.add(float(TamerData.rule("combat.stagger.wall_slam")))
		TamerFx.word(c.global_position, "Wall slam!", Pal.c("gold"))
	elif ahead == F.THORNS:
		c.take_terrain_damage(float(T()["thorn_damage"]), "Thorns!")
	if a.layout.f_at(from) == F.LEDGE and a.layout.f_at(c.global_position) != F.LEDGE and a.layout.f_at(c.global_position) != F.RAMP:
		c.take_terrain_damage(float(T()["fall_damage"]), "Knocked off!")
		c.stun_t = maxf(c.stun_t, float(T()["fall_stun"]))


## A move lands on the ground at `at` (radius `r`): it changes the arena by its element and weight.
static func on_impact(at: Vector2, r: float, m: Dictionary, damage: float) -> void:
	var a: Arena = arena()
	if a == null:
		return
	a.affect(at, r, m, damage >= float(T()["heavy_hit"]))
