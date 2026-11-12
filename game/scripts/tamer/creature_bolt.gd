class_name CreatureBolt
extends Node2D
## A creature's projectile: a glowing orb in its element's colours with a white core and a tapering trail. It hits
## each foe once (stops at the first unless it pierces) and bursts against cover, blocked ground or at the end of its
## range (it never homes: lead your shots). Where it bursts, it can change the ground (TerrainRules).

const HEIGHT: float = 12.0
const HIT_PAD: float = 5.0
const TRAIL_POINTS: int = 8
const ORB_PX: float = 9.0
const POP_RADIUS: float = 20.0

var user: Creature
var m: Dictionary
var dir: Vector2
var element: String
var _travel: float = 0.0
var _hit: Array[Combatant] = []
var _trail: Line2D
var _size: float = 1.0
var _range: float = 0.0


static func fire(by: Creature, move: Dictionary, from: Vector2, toward: Vector2) -> CreatureBolt:
	var b := CreatureBolt.new()
	b.user = by
	b.m = move
	b.dir = toward.normalized()
	b.element = CreatureCombat.move_element(by, move)
	b._size = float(move.get("size", 1.0))
	b._range = float(move["range"]) * TerrainRules.range_mult(by)
	b.position = from
	TamerGame.current.fx_layer.add_child(b)
	return b


func _ready() -> void:
	z_index = Fx.FX_Z
	var glow := Sprite2D.new()
	glow.texture = LightTex.soft(64)
	glow.material = Fx.glow_material()
	glow.modulate = TamerData.color(element, "core")
	glow.scale = Vector2.ONE * ORB_PX * 2.0 * _size / 32.0
	glow.position = Vector2(0, -HEIGHT)
	add_child(glow)
	var core := Sprite2D.new()
	core.texture = LightTex.soft(64)
	core.material = Fx.glow_material()
	core.modulate = Color(1.5, 1.5, 1.4)
	core.scale = Vector2.ONE * ORB_PX * 0.7 * _size / 32.0
	core.position = Vector2(0, -HEIGHT)
	add_child(core)
	_trail = Line2D.new()
	_trail.width = ORB_PX * _size
	_trail.width_curve = Curve.new()
	_trail.width_curve.add_point(Vector2(0, 0))
	_trail.width_curve.add_point(Vector2(1, 1))
	_trail.default_color = TamerData.color(element, "light", 0.7)
	_trail.material = Fx.glow_material()
	_trail.top_level = true
	_trail.z_index = Fx.FX_Z - 1
	add_child(_trail)


func _physics_process(delta: float) -> void:
	var step: float = float(m["speed"]) * float(TamerData.rule("combat.bolt_speed_mult")) * delta
	position += dir * step
	_travel += step
	_trail.add_point(global_position + Vector2(0, -HEIGHT))
	while _trail.get_point_count() > TRAIL_POINTS:
		_trail.remove_point(0)
	if TamerGame.current.blocks_shot(global_position) or _travel >= _range:
		_pop()
		return
	if not is_instance_valid(user):
		return
	for f: Combatant in user.foes():
		if _hit.has(f) or f.global_position.distance_to(global_position) > f.hit_radius() + HIT_PAD * _size:
			continue
		_hit.append(f)
		CreatureCombat.hit(user, f, m, dir)
		if not bool(m.get("pierce", false)):
			_pop()
			return


func _pop() -> void:
	TerrainRules.on_impact(global_position, POP_RADIUS * _size, m, float(m["damage"]))
	Fx.burst(get_parent(), global_position + Vector2(0, -HEIGHT), 8, Vector2(40, 120), 0.3, TamerData.sparks(element))
	queue_free()
