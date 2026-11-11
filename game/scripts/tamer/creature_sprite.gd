class_name CreatureSprite
extends Node2D
## How a creature looks and moves: its sheet (normal or shiny) with the emissive layer, a ground shadow, idle and
## gait frames with a squash-and-bob, an attack pose, the hit flash, the gold outline and ground ring while you
## steer it, a shiny's sparkle, dazed stars when it can be befriended, and fading out when it faints.

const ROWS: Dictionary = {"idle": 0, "move": 1, "act": 2}
const COLS: int = 4
const HIT_FLASH: float = 0.04
const HOT_TIME: float = 0.16
const HOT_AMOUNT: float = 0.5
const ACT_TIME: float = 0.2
const MOVING: float = 12.0              ## px/s: faster than this plays the gait
const BOB_SQUASH: float = 0.06
const RING_PULSE: float = 5.0
const SPARKLE_EVERY: float = 0.7
const STAR_COUNT: int = 3
const STAR_ORBIT := Vector2(11.0, 4.0)

var sprite: Sprite2D
var ring: Sprite2D                      ## under the one you steer
var stars: Node2D
var element: String
var hover: float = 0.0
var _fps: float = 8.0
var _t: float = 0.0
var _act_t: float = 0.0
var _flash_t: float = 0.0
var _hot_t: float = 0.0
var _sparkle_t: float = 0.0
var _shiny: bool = false
var _height: float = 24.0


func setup(rec: CreatureRecord) -> CreatureSprite:
	var meta: Dictionary = TamerData.sprites["creatures"][rec.species_id]
	element = rec.element()
	_shiny = rec.shiny
	_fps = float(rec.data().get("anim_fps", 8))
	hover = float(rec.data().get("hover", 0.0))
	var frame := Vector2(float(meta["frame"][0]), float(meta["frame"][1]))
	add_child(PropSprite.shadow(rec.radius() * 2.6))
	ring = _make_ring(rec.radius())
	sprite = Sprite2D.new()
	sprite.texture = PropSprite.tex("res://art/creatures/%s%s.png" % [rec.species_id, "_shiny" if rec.shiny else ""])
	sprite.hframes = COLS
	sprite.vframes = ROWS.size()
	sprite.offset = Vector2(0, -frame.y / 2.0 + (frame.y - float(meta["anchor"][1])))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/creature.gdshader")
	mat.set_shader_parameter("outline_color", Pal.c(String(TamerData.rule("control.outline"))))
	sprite.material = mat
	add_child(sprite)
	PropSprite.add_glow(sprite, "res://art/creatures/%s%s_glow.png" % [rec.species_id, "_shiny" if rec.shiny else ""])
	_height = frame.y * 0.55
	stars = Node2D.new()
	stars.visible = false
	stars.draw.connect(_draw_stars)
	add_child(stars)
	return self


func _make_ring(r: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = LightTex.ring()
	s.material = Fx.glow_material()
	s.modulate = Pal.c(String(TamerData.rule("control.outline")), 0.9)
	s.scale = Vector2(1.0, Fx.RING_SQUASH) * (r * 2.2) / 64.0
	s.z_index = -1
	s.show_behind_parent = true
	s.visible = false
	add_child(s)
	return s


func body_height() -> float:
	return _height + hover


## The one you steer wears a gold outline and a pulsing ring on the ground.
func set_highlight(on: bool) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("outline", 1.0 if on else 0.0)
	ring.visible = on


func set_dazed(on: bool) -> void:
	stars.visible = on


func act() -> void:
	_act_t = ACT_TIME


func flash() -> void:
	_flash_t = HIT_FLASH
	_hot_t = HIT_FLASH + HOT_TIME
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.05)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func animate(delta: float, vel: Vector2, facing: float) -> void:
	var real: float = delta / maxf(Engine.time_scale, 0.01)        # hit-stop must not stretch the flash
	_t += delta * _fps
	_act_t -= delta
	_flash_t = maxf(0.0, _flash_t - real)
	_hot_t = maxf(0.0, _hot_t - real)
	if absf(facing) > 0.1:
		sprite.flip_h = facing < 0.0
	var pose: String = "act" if _act_t > 0.0 else ("move" if vel.length() > MOVING else "idle")
	var n: int = 2 if pose == "act" else COLS
	var f: int = (1 if _act_t < ACT_TIME * 0.5 else 0) if pose == "act" else int(_t) % n
	sprite.frame = int(ROWS[pose]) * COLS + f
	var bob: float = sin(_t * 0.8) * (2.0 if hover > 0.0 else 0.0)
	sprite.position.y = -hover + bob
	if pose == "move" and hover <= 0.0:
		sprite.scale.y = 1.0 + sin(_t * PI) * BOB_SQUASH
	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("flash_color", Color.WHITE if _flash_t > 0.0 else TamerData.color(element))
	mat.set_shader_parameter("flash", 1.0 if _flash_t > 0.0 else HOT_AMOUNT * _hot_t / HOT_TIME)
	if ring.visible:
		ring.modulate.a = 0.55 + 0.35 * sin(_t * RING_PULSE / _fps * 2.0)
	_sparkle(delta)
	if stars.visible:
		stars.queue_redraw()


## A shiny glints now and then with little stars of light.
func _sparkle(delta: float) -> void:
	if not _shiny:
		return
	_sparkle_t -= delta
	if _sparkle_t <= 0.0:
		_sparkle_t = SPARKLE_EVERY * randf_range(0.6, 1.4)
		var at: Vector2 = Vector2(randf_range(-14.0, 14.0), -randf_range(4.0, _height + hover))
		Fx.burst(self, at, 5, Vector2(10, 40), 0.5, [Pal.c("sun"), Pal.c("gold"), Pal.c("amber", 0.0)], Vector2.UP, 180.0, Vector2(1.0, 1.6))


func _draw_stars() -> void:
	var top: float = -body_height() - 6.0
	for k: int in STAR_COUNT:
		var a: float = _t * 0.6 + TAU * k / STAR_COUNT
		var p := Vector2(cos(a) * STAR_ORBIT.x, top + sin(a) * STAR_ORBIT.y)
		stars.draw_rect(Rect2(p - Vector2(2, 0.5), Vector2(4, 1)), Pal.c("gold"))
		stars.draw_rect(Rect2(p - Vector2(0.5, 2), Vector2(1, 4)), Pal.c("gold"))
		stars.draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1, 1)), Pal.c("sun"))


## Faints: flashes white and fades, rising a little (a knock-out is never gory).
func fade_out(time: float) -> void:
	set_highlight(false)
	stars.visible = false
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate", Color(1.6, 1.6, 1.6, 0.0), time)
	tw.tween_property(sprite, "position:y", sprite.position.y - 10.0, time)
