class_name Camp
extends Node2D
## The rest point: a campfire in its own clearing. Walk in (with no fight nearby) and you rest: you and your team
## are healed and woken, the wild packs return, and your creatures sit around the fire (the one that was out walks
## over and sits too). The camp panel opens: pet and feed (bond, once each per rest) and spend materials on stats.
## Walking away ends the rest.

signal rested

const FLAME_COLORS: Array[String] = ["sun", "gold", "flame", "ember"]
const SAFE_RADIUS: float = 260.0        ## no awake wild creature this close, or there is no rest
const SIT_SQUASH: float = 0.88
const FIRE_LIGHT: float = 220.0

var g: TamerGame
var resting: bool = false
var petted: Dictionary = {}             ## CreatureRecord -> true, this rest
var fed: Dictionary = {}
var _sitters: Array[Node2D] = []
var _glow: Sprite2D
var _t: float = 0.0


func setup(game: TamerGame, at: Vector2) -> void:
	g = game
	position = at
	_flames()


func _flames() -> void:
	var cols: Array[Color] = []
	for c: String in FLAME_COLORS:
		cols.append(Pal.c(c))
	cols[cols.size() - 1].a = 0.0
	var p := CPUParticles2D.new()
	p.texture = PropSprite.tex(Fx.SPARK)
	p.amount = 40
	p.lifetime = 0.9
	p.position = Vector2(0, -6)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 5.0
	p.direction = Vector2.UP
	p.spread = 18.0
	p.gravity = Vector2(0, -30)
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 34.0
	p.scale_amount_min = 2.5
	p.scale_amount_max = 4.5
	p.color_ramp = Fx.ramp(cols)
	p.material = Fx.glow_material()
	p.z_index = Fx.FX_Z
	add_child(p)
	_glow = Sprite2D.new()
	_glow.texture = LightTex.soft(128)
	_glow.material = Fx.glow_material()
	_glow.modulate = Pal.c("flame", 0.35)
	_glow.scale = Vector2.ONE * FIRE_LIGHT / 64.0
	_glow.position = Vector2(0, -4)
	add_child(_glow)


func radius() -> float:
	return float(TamerData.rule("camp.radius"))


func _process(delta: float) -> void:
	_t += delta
	_glow.modulate.a = 0.3 + 0.06 * sin(_t * 9.0) + 0.04 * sin(_t * 23.0)
	for s: Node2D in _sitters:
		(s as CreatureSprite).animate(delta, Vector2.ZERO, -1.0 if s.position.x > position.x else 1.0)
	var near: bool = g.trainer.alive() and g.trainer.global_position.distance_to(global_position) < radius()
	if near and not resting and _safe():
		_rest()
	elif not near and resting:
		_leave()


func _safe() -> bool:
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var c := n as Creature
		if c.brain is WildBrain and (c.brain as WildBrain).awake and c.global_position.distance_to(global_position) < SAFE_RADIUS:
			return false
	return true


func _rest() -> void:
	resting = true
	petted.clear()
	fed.clear()
	g.trainer.heal(g.trainer.max_life)
	g.team.rest()
	for r: CreatureRecord in g.team.members:
		r.add_bond(float(TamerData.rule("bond.camp_rest")))
	g.spawner.spawn_all(global_position)
	Audio.sfx("lamp_lit", -6.0, 0.9)
	Fx.ring(g.fx_layer, global_position, 10.0, radius(), Pal.c("amber"), 0.6)
	g.hud.notice("You rest by the fire. Everyone is healed, and the wild creatures are back.")
	_sit_down()
	rested.emit()


## Every team member sits on a ring around the fire, facing it; the one that was out walks over to its seat.
func sit_spots(n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var r: float = float(TamerData.rule("camp.sit_radius"))
	for k: int in n:
		var a: float = PI + PI * (float(k) / (n - 1)) if n > 1 else -PI * 0.5     # left, behind, right: you sit at the front
		out.append(global_position + Vector2(cos(a) * r * 1.4, sin(a) * r * 1.25 + 4.0))
	return out


func _sit_down() -> void:
	var spots: Array[Vector2] = sit_spots(g.team.members.size())
	for i: int in g.team.members.size():
		var rec: CreatureRecord = g.team.members[i]
		if g.field.partner != null and g.field.partner.rec == rec:
			g.field.partner.brain = CampBrain.new(g.field.partner, spots[i], global_position)
			continue
		var s := CreatureSprite.new().setup(rec)
		s.position = g.layout.free_spot_near(spots[i], rec.radius())
		s.scale.y = SIT_SQUASH
		g.world.add_child(s)
		Fx.burst(g.fx_layer, s.position + Vector2(0, -10), 12, Vector2(30, 90), 0.4, TamerData.sparks(rec.element()))
		_sitters.append(s)


func _leave() -> void:
	resting = false
	for s: Node2D in _sitters:
		if is_instance_valid(s):
			Fx.burst(g.fx_layer, s.position + Vector2(0, -10), 8, Vector2(30, 90), 0.3, [Pal.c("sun"), Pal.c("gold"), Pal.c("amber", 0.0)])
			s.queue_free()
	_sitters.clear()
	var p: Creature = g.field.partner
	if p != null and p.brain is CampBrain:
		p.brain = PartnerBrain.new(p)
	g.hud.camp_panel.close()


## Where a team member is shown at the fire (its sitter, or the partner itself), for hearts and bursts.
func spot_of(rec: CreatureRecord) -> Vector2:
	if g.field.partner != null and g.field.partner.rec == rec:
		return g.field.partner.global_position
	var i: int = g.team.members.find(rec)
	var sitters_before: int = 0
	for k: int in i:
		if g.field.partner == null or g.field.partner.rec != g.team.members[k]:
			sitters_before += 1
	return _sitters[sitters_before].position if sitters_before < _sitters.size() else global_position


## Pet (or feed): bond grows, hearts rise. Once per rest each.
func care(rec: CreatureRecord, kind: String) -> bool:
	var done: Dictionary = petted if kind == "pet" else fed
	if not resting or done.has(rec):
		return false
	done[rec] = true
	rec.add_bond(float(TamerData.rule("bond." + kind)))
	var at: Vector2 = spot_of(rec) + Vector2(0, -16)
	Fx.burst(g.fx_layer, at, 16, Vector2(20, 70), 0.9, [Pal.c("sun"), Pal.c("rose"), Pal.c("blood", 0.0)], Vector2.UP, 50.0, Vector2(1.5, 2.5))
	TamerFx.word(at, "Happy!" if kind == "pet" else "Yum!", Pal.c("rose"))
	Audio.sfx("pickup", -6.0, 1.5 if kind == "pet" else 1.1)
	return true
