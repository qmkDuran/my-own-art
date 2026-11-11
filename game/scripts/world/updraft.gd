class_name Updraft
extends Node2D
## The Rising Falls: a column of water falling upward. Standing in it pushes you up-screen (north); drops rise
## through it so you can see where it is. It pushes enemies too.

const PUSH: float = 220.0
const DROPS: int = 36

var radius: float = 70.0


static func make(parent: Node, at: Vector2, r: float) -> Updraft:
	var u := Updraft.new()
	u.position = at
	u.radius = r
	parent.add_child(u)
	return u


func _ready() -> void:
	z_index = -14
	z_as_relative = false
	material = Fx.unshaded()
	var d: CPUParticles2D = Fx.motes(self, Vector2(radius * 0.8, radius * 0.5), DROPS, Pal.c("glint", 0.9))
	d.local_coords = true
	d.direction = Vector2.UP
	d.spread = 5.0
	d.initial_velocity_min = 40.0
	d.initial_velocity_max = 90.0
	d.lifetime = 1.6
	d.preprocess = 1.6


func _physics_process(delta: float) -> void:
	var p: Player = Game.current.player
	if p.global_position.distance_to(global_position) < radius and not p.untouchable():
		p.push(Vector2.UP * PUSH * delta * 8.0)
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(Pal.c("glass_lt"), 0.08))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(Pal.c("glint"), 0.25), 1.0)
