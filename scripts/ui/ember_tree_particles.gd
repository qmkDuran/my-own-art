class_name EmberTreeParticles
extends RefCounted
## The Ember Tree's particle effects: embers drifting up around the tree, and the burst
## of sparks when a node is ignited.


## Slow embers drifting upward across a circle of `radius` around the tree's centre.
static func make_drifting_embers(radius: float) -> CPUParticles2D:
	var embers := CPUParticles2D.new()
	embers.amount = 60
	embers.lifetime = 5.0
	embers.preprocess = 5.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = radius
	embers.direction = Vector2.UP
	embers.spread = 25.0
	embers.gravity = Vector2(0, -8)
	embers.initial_velocity_min = 3.0
	embers.initial_velocity_max = 12.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	embers.color_ramp = _fade_ramp(EmberTreePalette.GOLD, EmberTreePalette.ORANGE, EmberTreePalette.RED)
	return embers


## A one-shot burst of sparks at `point` that frees itself when done.
## Add it to the tree, then set `emitting` to true.
static func make_ignite_burst(point: Vector2) -> CPUParticles2D:
	var burst := CPUParticles2D.new()
	burst.position = point
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 24
	burst.lifetime = 0.7
	burst.spread = 180.0
	burst.initial_velocity_min = 50.0
	burst.initial_velocity_max = 120.0
	burst.gravity = Vector2(0, 80)
	burst.scale_amount_min = 2.0
	burst.scale_amount_max = 4.0
	burst.color_ramp = _fade_ramp(EmberTreePalette.CREAM, EmberTreePalette.ORANGE, EmberTreePalette.RED)
	burst.finished.connect(burst.queue_free)
	return burst


static func _fade_ramp(start: Color, middle: Color, end: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([start, middle, Color(end, 0.0)])
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return ramp
