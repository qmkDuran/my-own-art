class_name Fx
extends RefCounted
## Particle effects: drifting motes of light, gleaming sparkles, rising incense smoke.

const SPARK: String = "res://art/spark.png"
const FX_Z: int = 6


static func _base(parent: Node, center: Vector2, extents: Vector2, amount: int, life: float) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = load(SPARK) as Texture2D
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.position = center
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.gravity = Vector2.ZERO
	p.z_index = FX_Z
	p.material = SpriteFactory.additive()
	parent.add_child(p)
	return p


static func _ramp(points: Array) -> Gradient:
	# points: [[offset, Color], ...]; the first two replace the default end points
	var g := Gradient.new()
	g.set_color(0, points[0][1])
	g.set_color(1, points[1][1])
	for k: int in range(2, points.size()):
		g.add_point(points[k][0], points[k][1])
	return g


## Motes of light drifting through an area (the glory that fills the city, Rev 21:23).
static func motes(parent: Node, area: Rect2, amount: int, drift: Vector2, tint: Color) -> CPUParticles2D:
	var p := _base(parent, area.get_center(), area.size / 2.0, amount, 7.0)
	p.direction = drift.normalized() if drift != Vector2.ZERO else Vector2.UP
	p.spread = 25.0
	p.initial_velocity_min = drift.length() * 0.6
	p.initial_velocity_max = drift.length() * 1.6
	p.scale_amount_min = 0.67
	p.scale_amount_max = 1.0
	p.color_ramp = _ramp([[0.0, Color(tint, 0.0)], [1.0, Color(tint, 0.0)], [0.3, Color(tint, 0.9)], [0.7, Color(tint, 0.6)]])
	return p


## Gleaming points of light (also the "eyes" glinting on the living creatures' wings).
static func sparkles(parent: Node, center: Vector2, extents: Vector2, amount: int) -> CPUParticles2D:
	var p := _base(parent, center, extents, amount, 3.0)
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 0.67
	p.scale_amount_max = 1.0
	p.color_ramp = _ramp([[0.0, Color(1, 1, 0.85, 0)], [1.0, Color(1, 1, 0.85, 0)], [0.5, Color(1, 1, 0.9, 0.95)]])
	return p


## Odours rising from a golden vial (Rev 5:8; 8:4).
static func smoke(parent: Node, at: Vector2) -> CPUParticles2D:
	var p := _base(parent, at, Vector2(2, 1), 4, 2.6)
	p.z_index = 2
	p.material = null
	p.direction = Vector2.UP
	p.spread = 12.0
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 9.0
	p.scale_amount_min = 0.67
	p.scale_amount_max = 1.0
	p.color_ramp = _ramp([[0.0, Color(1, 1, 1, 0.0)], [1.0, Color(0.9, 0.95, 1, 0.0)], [0.25, Color(1, 1, 1, 0.7)]])
	return p


## Soft motes of light rising slowly over the land outside the city (Rev 21:24).
static func glow_motes(parent: Node, area: Rect2, amount: int) -> CPUParticles2D:
	var p := _base(parent, area.get_center(), area.size / 2.0, amount, 7.0)
	p.direction = Vector2.UP
	p.spread = 30.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 0.67
	p.scale_amount_max = 1.0
	p.color_ramp = _ramp([[0.0, Color(1, 1, 0.85, 0)], [1.0, Color(1, 1, 0.85, 0)], [0.5, Color(1, 1, 0.9, 0.7)]])
	return p
