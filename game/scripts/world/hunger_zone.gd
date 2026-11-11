class_name HungerZone
extends Node2D
## A moth nest's hunger: inside it the lantern's Light drains, slowly; violet dust drifts so you can see where it
## is. Light it up (a lit waylamp nearby, or kill what nests there) and it still drains, so move through.

const DRAIN: float = 3.0
const DUST: int = 40

var radius: float = 150.0
var life: float = 0.0                 ## > 0: a dust cloud that settles after this long
var _dust: CPUParticles2D


static func make(parent: Node, at: Vector2, r: float) -> HungerZone:
	var h := HungerZone.new()
	h.position = at
	h.radius = r
	parent.add_child(h)
	return h


func _ready() -> void:
	z_index = -14
	z_as_relative = false
	material = Fx.unshaded()
	_dust = Fx.motes(self, Vector2(radius, radius * 0.7), DUST, Pal.c("violet_lt", 0.9))
	_dust.local_coords = true


func inside(p: Vector2) -> bool:
	return p.distance_to(global_position) < radius


func _process(delta: float) -> void:
	if life > 0.0:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
	var p: Player = Game.current.player
	if inside(p.global_position) and not p.dead:
		p.light.add(-DRAIN * delta)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(Pal.c("violet"), 0.07))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(Pal.c("violet_lt"), 0.18), 1.0)
