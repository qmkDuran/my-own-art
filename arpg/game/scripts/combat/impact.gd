class_name Impact
extends RefCounted
## Game feel for hits and blasts: sparks, shadow bursts, dust, debris, scorched craters, rings and screen shake
## (scaled by "screen_shake" in data/settings.json; 0 turns it off). All drawn or emitted by code.

const SPARK := Color(1.0, 0.95, 0.7)
const SHADOW := Color(0.14, 0.09, 0.2)
const EMBER := Color(1.0, 0.45, 0.15)
const DUST := Color(0.55, 0.52, 0.58)

static var _shake_tween: Tween


static func shake(node: Node, strength: float) -> void:
	var k: float = float(GameData.settings.get("screen_shake", 1.0)) * strength
	var cam := node.get_viewport().get_camera_2d()
	if cam == null or k <= 0.0:
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = cam.create_tween()
	for i: int in 5:
		var f: float = k * (1.0 - i / 5.0)
		_shake_tween.tween_property(cam, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * f, 0.03)
	_shake_tween.tween_property(cam, "offset", Vector2.ZERO, 0.04)


static func _burst(parent: Node, at: Vector2, amount: int, speed: Vector2, life: float, col: Color, add: bool,
		spread: float = 180.0, size: float = 1.0, gravity: Vector2 = Vector2.ZERO) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = load(Fx.SPARK) as Texture2D
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.position = at
	p.direction = Vector2.UP
	p.spread = spread
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = gravity
	p.scale_amount_min = size
	p.scale_amount_max = size * 1.8
	p.damping_min = speed.x * 0.8
	p.damping_max = speed.y
	p.z_index = 9
	p.color_ramp = Fx._ramp([[0.0, col], [1.0, Color(col, 0.0)]])
	if add:
		p.material = SpriteFactory.additive()
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(life + 0.2).timeout.connect(p.queue_free)
	return p


## Every hit: a spark spray and a puff of shadow torn off the demon; criticals flash bigger and shake.
static func hit(parent: Node, at: Vector2, crit: bool) -> void:
	_burst(parent, at, 10 if crit else 6, Vector2(60, 160), 0.25, SPARK, true, 120.0)
	_burst(parent, at, 5, Vector2(10, 40), 0.5, SHADOW, false, 180.0, 1.6)
	if crit:
		SkillFx.ring(parent, at, 26.0, SPARK, 0.18)
		shake(parent, 2.5)


## A skill's blast: a ring, a shower of light and a cloud of dust, with shake.
static func blast(parent: Node, at: Vector2, radius: float, col: Color, power: float) -> void:
	SkillFx.ring(parent, at, radius, col, 0.45)
	_burst(parent, at + Vector2(0, -14), int(14 * power), Vector2(80, 220) * power, 0.4, col, true)
	_burst(parent, at, int(16 * power), Vector2(30, 110) * power, 0.9, DUST, false, 180.0, 2.2, Vector2(0, -10))
	shake(parent, 3.0 * power)


## Descent landing: a scorched crater that fades, flying debris, dust and a heavy shake.
static func crater(parent: Node, at: Vector2, radius: float) -> void:
	var c := Crater.new()
	c.position = at
	c.radius = radius
	parent.add_child(c)
	_burst(parent, at, 18, Vector2(90, 200), 0.6, Color(0.35, 0.3, 0.38), false, 160.0, 1.8, Vector2(0, 320))
	_burst(parent, at, 20, Vector2(40, 120), 1.0, DUST, false, 180.0, 2.4)
	SkillFx.ring(parent, at, radius * 1.3, Color(1, 0.95, 0.7), 0.35)
	shake(parent, 6.0)


## A demon's end: a burst of shadow with embers and a dark ring.
static func death(parent: Node, at: Vector2, rim: Color, big: bool) -> void:
	_burst(parent, at, 26 if big else 16, Vector2(30, 120), 0.9, SHADOW, false, 180.0, 2.4)
	_burst(parent, at, 14 if big else 8, Vector2(50, 150), 0.8, EMBER, true, 140.0, 1.0, Vector2(0, -40))
	SkillFx.ring(parent, at, 44.0 if big else 30.0, rim, 0.3)
	shake(parent, 3.0 if big else 1.2)


## A bursting cinder or ember-burst champion.
static func explosion(parent: Node, at: Vector2, radius: float) -> void:
	SkillFx.ring(parent, at, radius, EMBER, 0.35)
	_burst(parent, at, 24, Vector2(80, 220), 0.6, EMBER, true)
	_burst(parent, at, 16, Vector2(30, 90), 1.0, SHADOW, false, 180.0, 2.6)
	shake(parent, 4.0)
