class_name ThrownLantern
extends Node2D
## Lantern Toss in flight and on the ground: arcs to the target, lands with a blow, burns and lights the ground
## around it (enemies there are no longer Shrouded, and with Beacon take more damage), then flies home — or
## sooner if called back — hitting what it passes.

signal returned

const ARC_HEIGHT: float = 46.0
const IMPACT_RADIUS: float = 60.0
const TICK: float = 0.5
const CATCH: float = 14.0
const PASS_RADIUS: float = 20.0
const TRAIL_EVERY: float = 40.0
const TRAIL_RADIUS: float = 22.0
const TRAIL_TIME: float = 2.0
const TRAIL_PCT: float = 20.0
const LIGHT_ENERGY: float = 1.15

var skill: LanternToss
var from: Vector2
var to: Vector2
var state: String = "out"
var _t: float = 0.0
var _fly: float = 0.1
var _tick: float = 0.0
var _hit_back: Array[Enemy] = []
var _trail_d: float = 0.0
var _last_pos: Vector2
var _sprite: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	add_to_group(LightField.GROUP)
	_fly = maxf(0.12, from.distance_to(to) / float(skill.data["flight_speed"]))
	position = from
	_last_pos = from
	add_child(PropSprite.shadow(16.0))
	_sprite = Sprite2D.new()
	_sprite.texture = PropSprite.tex("res://art/fx/lantern.png")
	_sprite.offset = Vector2(0, -9)
	add_child(_sprite)
	var glow := Sprite2D.new()
	glow.texture = _sprite.texture
	glow.offset = _sprite.offset
	glow.material = Fx.glow_material()
	_sprite.add_child(glow)
	_light = PointLight2D.new()
	_light.texture = LightTex.banded()
	_light.color = LanternLight.COLOR
	_light.energy = LIGHT_ENERGY
	add_child(_light)


func light_pos() -> Vector2:
	return global_position


func light_radius() -> float:
	return float(skill.data["light_radius"]) if state == "landed" else float(skill.data["light_radius"]) * 0.4


func _physics_process(delta: float) -> void:
	_t += delta
	match state:
		"out": _fly_out()
		"landed": _burn(delta)
		"back": _fly_back(delta)
	_light.texture_scale = light_radius() / LanternLight.TEX_RADIUS
	_ember_trail()


func _fly_out() -> void:
	var k: float = minf(1.0, _t / _fly)
	position = from.lerp(to, k)
	_sprite.position.y = -sin(k * PI) * ARC_HEIGHT
	_sprite.rotation = k * TAU
	if k >= 1.0:
		_land()


func _land() -> void:
	state = "landed"
	_t = 0.0
	_sprite.rotation = 0.0
	_sprite.position.y = 0.0
	Audio.sfx("lantern_land", -4.0)
	CameraRig.shake(0.2)
	Fx.flash(get_parent(), position, 160.0, Pal.c("gold"), 1.6, 0.3)
	Fx.burst(get_parent(), position, 18, Vector2(60, 180), 0.45, [Pal.c("sun"), Pal.c("amber"), Pal.c("ember", 0.0)])
	var more: float = 1.0 + skill.val("impact_pct") / 100.0
	for e: Enemy in skill.enemies_in_arc(position, Vector2.RIGHT, IMPACT_RADIUS, 360.0):
		Combat.hit_enemy(e, skill.roll(float(skill.data["damage_pct"])), skill.opts({"dir": e.global_position - position,
			"more": more, "knockback": 40.0 * more, "heavy": true}))


func _burn(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		for e: Enemy in skill.enemies_in_arc(position, Vector2.RIGHT, light_radius(), 360.0):
			Combat.hit_enemy(e, skill.roll(float(skill.data["burn_pct"])), skill.opts({"dot": true}))
			if skill.val("exposed_pct") > 0.0:
				e.expose(skill.val("exposed_pct"), TICK * 1.5)
	if _t >= skill.duration():
		go_home()


func go_home() -> void:
	if state == "back":
		return
	state = "back"
	_t = 0.0
	Audio.sfx("lantern_throw", -7.0, 1.2)


func _fly_back(delta: float) -> void:
	var home: Vector2 = skill.p.lantern_pos() + Vector2(0, 40)
	var spd: float = float(skill.data["flight_speed"]) * 1.2
	position = position.move_toward(home, spd * delta)
	_sprite.rotation += delta * 14.0
	var more: float = 1.0 + skill.val("return_pct") / 100.0
	for e: Enemy in skill.enemies_in_arc(position, Vector2.RIGHT, PASS_RADIUS, 360.0):
		if _hit_back.has(e):
			continue
		_hit_back.append(e)
		var pull: Vector2 = (skill.p.global_position - e.global_position) if skill.rank("tether") > 0 else (e.global_position - position)
		Combat.hit_enemy(e, skill.roll(float(skill.data["return_pct"])), skill.opts({"dir": pull, "more": more,
			"knockback": 90.0 if skill.rank("tether") > 0 else 20.0}))
	if position.distance_to(home) < CATCH:
		returned.emit()
		Audio.sfx("lantern_catch", -8.0)
		queue_free()


func _ember_trail() -> void:
	if skill.rank("ember_trail") == 0 or state == "landed":
		return
	_trail_d += position.distance_to(_last_pos)
	_last_pos = position
	if _trail_d >= TRAIL_EVERY:
		_trail_d = 0.0
		var b: Vector2 = skill.base_range(TRAIL_PCT)
		BurningGround.spawn(get_parent(), position, TRAIL_RADIUS, TRAIL_TIME, (b.x + b.y) * 0.5, skill)
