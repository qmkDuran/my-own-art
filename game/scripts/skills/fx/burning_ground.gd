class_name BurningGround
extends Node2D
## Afterglow / Ember Trail: ground that keeps burning for a while, hurting enemies standing in it.

const TICK: float = 0.5
const EMBERS: int = 3

var radius: float
var dps_base: float
var time: float
var skill: Skill
var _t: float = 0.0
var _tick: float = 0.0


static func spawn(parent: Node, at: Vector2, r: float, seconds: float, base_per_second: float, by: Skill) -> BurningGround:
	var g := BurningGround.new()
	g.position = at
	g.radius = r
	g.time = seconds
	g.dps_base = base_per_second
	g.skill = by
	g.material = Fx.glow_material()
	g.z_index = -14
	g.z_as_relative = false
	parent.add_child(g)
	return g


func _process(delta: float) -> void:
	_t += delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		for e: Enemy in skill.enemies_in_arc(global_position, Vector2.RIGHT, radius, 360.0):
			Combat.hit_enemy(e, dps_base * TICK, skill.opts({"dot": true}))
		for k: int in EMBERS:
			var at: Vector2 = global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf() * radius
			Fx.burst(get_parent(), at, 2, Vector2(10, 30), 0.5, [Pal.c("gold"), Pal.c("ember", 0.0)], Vector2.UP, 20.0)
	if _t > time:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade: float = clampf((time - _t) / 0.4, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(Pal.c("ember"), 0.16 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(Pal.c("flame"), 0.45 * fade), 2.0)
