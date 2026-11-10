class_name Fx
extends RefCounted
## Particle effects: motes, sparkles, rising prayers (incense), shadow puffs, embers and falling ash.

const SPARK: String = "res://art/fx/spark.png"
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


## A dark puff where a shadow comes apart (normal blend: it darkens).
static func shadow_puff(parent: Node, at: Vector2) -> CPUParticles2D:
	var p := _base(parent, at, Vector2(12, 14), 22, 1.1)
	p.material = null
	p.preprocess = 0.0
	p.one_shot = true
	p.explosiveness = 0.8
	p.direction = Vector2.UP
	p.spread = 70.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 34.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5
	p.color_ramp = _ramp([[0.0, Color(0.16, 0.1, 0.2, 0.9)], [1.0, Color(0.2, 0.12, 0.3, 0.0)]])
	parent.get_tree().create_timer(1.6).timeout.connect(p.queue_free)
	return p


## Prayers rising like incense (Rev 8:4): slow golden light drifting up from the one who prays.
static func incense(parent: Node, at: Vector2) -> CPUParticles2D:
	var p := _base(parent, at, Vector2(10, 4), 18, 3.2)
	p.direction = Vector2.UP
	p.spread = 10.0
	p.initial_velocity_min = 14.0
	p.initial_velocity_max = 24.0
	p.scale_amount_min = 0.67
	p.scale_amount_max = 1.3
	p.color_ramp = _ramp([[0.0, Color(1, 0.9, 0.5, 0)], [1.0, Color(1, 1, 0.8, 0)], [0.3, Color(1, 0.92, 0.6, 0.9)]])
	return p


## Embers over a burning wreck.
static func embers(parent: Node, at: Vector2) -> CPUParticles2D:
	var p := _base(parent, at, Vector2(30, 6), 26, 1.8)
	p.direction = Vector2.UP
	p.spread = 25.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 46.0
	p.color_ramp = _ramp([[0.0, Color(1, 0.6, 0.2, 1)], [1.0, Color(0.9, 0.2, 0.1, 0)]])
	return p


## Ash drifting down over the whole zone (the time of distress, Dan 12:1).
static func ash(parent: Node, area: Rect2, amount: int) -> CPUParticles2D:
	var p := _base(parent, area.get_center(), area.size / 2.0, amount, 9.0)
	p.material = null
	p.direction = Vector2(0.3, 1.0)
	p.spread = 20.0
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 16.0
	p.color_ramp = _ramp([[0.0, Color(0.7, 0.68, 0.75, 0)], [1.0, Color(0.6, 0.58, 0.65, 0)], [0.5, Color(0.75, 0.72, 0.8, 0.8)]])
	return p


## Smoke rising from the Abyss "like the smoke from a gigantic furnace" (Rev 9:2): a dark column (normal blend).
static func abyss_smoke(parent: Node, at: Vector2, extents: Vector2) -> CPUParticles2D:
	var p := _base(parent, at, extents, 90, 6.0)
	p.material = null
	p.z_index = 14
	p.direction = Vector2.UP
	p.spread = 12.0
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	p.color_ramp = _ramp([[0.0, Color(0.12, 0.06, 0.1, 0.0)], [1.0, Color(0.1, 0.08, 0.12, 0.0)], [0.2, Color(0.18, 0.08, 0.1, 0.85)],
		[0.6, Color(0.12, 0.09, 0.14, 0.6)]])
	return p


## A puff of fire and smoke from a mouth, toward `dir` (Rev 9:17).
static func flame(parent: Node, at: Vector2, dir: Vector2) -> CPUParticles2D:
	var p := _base(parent, at, Vector2(2, 2), 12, 0.5)
	p.preprocess = 0.0
	p.one_shot = true
	p.explosiveness = 0.6
	p.direction = dir
	p.spread = 22.0
	p.initial_velocity_min = 180.0
	p.initial_velocity_max = 260.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color_ramp = _ramp([[0.0, Color(1, 0.9, 0.4, 1)], [1.0, Color(0.25, 0.15, 0.15, 0)], [0.4, Color(1, 0.45, 0.1, 0.9)]])
	p.emitting = true
	parent.get_tree().create_timer(0.8).timeout.connect(p.queue_free)
	return p
