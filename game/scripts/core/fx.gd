class_name Fx
extends RefCounted
## Visual effects. The rule: the world is dark and muted, abilities are bright, saturated and additive, and every
## big moment briefly lights its surroundings (flash lights). Effects free themselves.

const SPARK: String = "res://art/fx/spark.png"
const FX_Z: int = 20
const GROUND_LIGHT_MASK: int = 2
const FLOOR_MASK: int = 32        ## only the ground: the lantern's shadow-casting light touches just this
const STANDING_MASK: int = 64     ## everything standing up (props, trees, people): lit by the lantern without shadows                     ## light layer the ground, trees and props also listen on

const RING_SQUASH: float = 0.6      ## shockwaves lie on the ground, seen at an angle

static var layer: Node2D            ## the effects layer of the scene being played (Game or the tamer prototype)
static var flash_gain: float = 1.0  ## scales flash lights: a daylit scene (the tamer meadow) needs far less than the Dusk
static var screen: Node             ## the UI root full-screen flashes go into (set by the same scene)
static var _glow_mat: CanvasItemMaterial
static var _add_mat: CanvasItemMaterial
static var _unshaded_mat: CanvasItemMaterial


## Unlit + additive: emissive layers, light effects (glow in the dark at full strength).
static func glow_material() -> CanvasItemMaterial:
	if _glow_mat == null:
		_glow_mat = CanvasItemMaterial.new()
		_glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _glow_mat


## Unlit, normal blend: things that must read in the dark at their true colour (telegraphs, labels).
static func unshaded() -> CanvasItemMaterial:
	if _unshaded_mat == null:
		_unshaded_mat = CanvasItemMaterial.new()
		_unshaded_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _unshaded_mat


static func _free_after(n: Node, seconds: float) -> void:
	n.get_tree().create_timer(seconds, false).timeout.connect(n.queue_free)


static func ramp(cols: Array[Color]) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, cols[0])
	g.set_color(1, cols[cols.size() - 1])
	for k: int in range(1, cols.size() - 1):
		g.add_point(float(k) / (cols.size() - 1), cols[k])
	return g


## A one-shot burst of glowing particles.
static func burst(parent: Node, at: Vector2, amount: int, speed: Vector2, life: float, cols: Array[Color],
		dir: Vector2 = Vector2.ZERO, spread: float = 180.0, scale_range: Vector2 = Vector2(1, 1), additive: bool = true) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = PropSprite.tex(SPARK)
	p.amount = maxi(1, amount)
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.position = at
	p.direction = dir if dir != Vector2.ZERO else Vector2.UP
	p.spread = spread
	p.gravity = Vector2.ZERO
	p.damping_min = speed.y * 1.2
	p.damping_max = speed.y * 1.6
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.scale_amount_min = scale_range.x
	p.scale_amount_max = scale_range.y
	p.color_ramp = ramp(cols)
	p.z_index = FX_Z
	p.material = glow_material() if additive else unshaded()
	parent.add_child(p)
	p.emitting = true
	_free_after(p, life + 0.2)
	return p


## Sparks off a hit, flying away from the attacker.
static func hit_sparks(parent: Node, at: Vector2, dir: Vector2, crit: bool) -> void:
	var cols: Array[Color] = [Pal.c("sun"), Pal.c("gold"), Pal.c("flame", 0.0)]
	burst(parent, at, 14 if crit else 7, Vector2(70, 190 if crit else 140), 0.32, cols, dir, 55.0, Vector2(1, 1.6))


## A brief point light: the burst lights the floor, trees and enemies around it, then fades.
static func flash(parent: Node, at: Vector2, radius: float, col: Color, energy: float = 1.4, time: float = 0.25) -> void:
	var l := PointLight2D.new()
	l.texture = LightTex.soft(256)
	l.texture_scale = radius / 128.0
	l.color = col
	l.energy = energy * flash_gain
	l.position = at
	l.range_item_cull_mask = GROUND_LIGHT_MASK          # flashes light the ground and props, never bodies (no washout)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "energy", 0.0, time).set_ease(Tween.EASE_IN)      # holds bright, then drops: reads as a pulse
	tw.tween_callback(l.queue_free)


## An additive halo that swells and fades (the "bloom" of a big effect).
static func halo(parent: Node, at: Vector2, radius: float, col: Color, time: float = 0.3) -> void:
	var s := Sprite2D.new()
	s.texture = LightTex.soft(128)
	s.material = glow_material()
	s.modulate = col
	s.position = at
	s.z_index = FX_Z
	s.scale = Vector2.ONE * radius / 64.0 * 0.4
	parent.add_child(s)
	var tw := s.create_tween()
	tw.set_parallel()
	tw.tween_property(s, "scale", Vector2.ONE * radius / 64.0, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(s, "modulate:a", 0.0, time)
	tw.chain().tween_callback(s.queue_free)


## A shockwave: a bright ring that races out from r0 to r1 and fades.
static func ring(parent: Node, at: Vector2, r0: float, r1: float, col: Color, time: float) -> void:
	var s := Sprite2D.new()
	s.texture = LightTex.ring()
	s.material = glow_material()
	s.modulate = col
	s.position = at
	s.z_index = FX_Z
	s.scale = Vector2(1.0, RING_SQUASH) * r0 / 64.0
	parent.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", Vector2(1.0, RING_SQUASH) * r1 / 64.0, time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "modulate:a", 0.0, time).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(s.queue_free)


## A white-hot core that sits for a couple of frames and is gone (the instant of contact).
static func core(parent: Node, at: Vector2, radius: float, time: float) -> void:
	var s := Sprite2D.new()
	s.texture = LightTex.soft(64)
	s.material = glow_material()
	s.modulate = Color(1.6, 1.6, 1.5)
	s.position = at
	s.z_index = FX_Z + 1
	s.scale = Vector2.ONE * radius / 32.0
	parent.add_child(s)
	s.get_tree().create_timer(time, true, false, true).timeout.connect(s.queue_free)


## A full-screen flash for the biggest spells (Flare, Noon): the whole view goes bright for an instant.
static func screen_flash(col: Color, alpha: float, time: float) -> void:
	if not is_instance_valid(screen):
		return
	var r := ColorRect.new()
	r.color = Color(col, alpha)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.material = glow_material()
	screen.add_child(r)
	screen.move_child(r, 0)
	var tw := r.create_tween()
	tw.tween_property(r, "color:a", 0.0, time).set_ease(Tween.EASE_OUT)
	tw.tween_callback(r.queue_free)


## Death of a Dusk creature: it comes apart into dark smoke, glass and a few embers of the light that killed it.
static func death_burst(parent: Node, at: Vector2, size: float, glass: bool) -> void:
	var dark: Array[Color] = [Pal.c("violet", 0.9), Pal.c("night", 0.7), Pal.c("void", 0.0)]
	burst(parent, at, int(14 * size), Vector2(30, 90 * size), 0.7, dark, Vector2.UP, 180.0, Vector2(2, 3.5), false)
	var embers: Array[Color] = [Pal.c("sun"), Pal.c("amber"), Pal.c("ember", 0.0)]
	burst(parent, at, int(10 * size), Vector2(60, 160 * size), 0.55, embers, Vector2.UP, 180.0, Vector2(1, 1.5))
	if glass:
		var shards: Array[Color] = [Pal.c("glint"), Pal.c("glass_lt"), Pal.c("glass", 0.0)]
		burst(parent, at, int(12 * size), Vector2(80, 200 * size), 0.6, shards, Vector2.UP, 180.0, Vector2(1, 2))
	halo(parent, at, 50.0 * size, Pal.c("violet_lt", 0.6), 0.35)


## Ambient motes drifting in the air around a point (attach to the camera).
static func motes(parent: Node, extents: Vector2, amount: int, col: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = PropSprite.tex(SPARK)
	p.amount = amount
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2(0.3, -1.0)
	p.spread = 40.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 9.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.0
	p.color_ramp = ramp([Color(col, 0.0), Color(col, 0.7), Color(col, 0.0)])
	p.material = glow_material()
	p.local_coords = false
	p.z_index = FX_Z
	parent.add_child(p)
	return p
