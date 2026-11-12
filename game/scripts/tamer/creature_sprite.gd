class_name CreatureSprite
extends Node2D
## How a creature looks and moves: its sheet (normal or shiny) with the emissive layer, a ground shadow, idle and
## gait frames with a squash-and-bob, an attack pose, the hit flash, the gold outline and ground ring while you
## steer it, a shiny's sparkle, dazed stars when it can be synced, see-through while hidden, and fading out when
## it faints.

const ROWS: Dictionary = {"idle": 0, "move": 1, "act": 2}
const COLS: int = 4
const HIT_FLASH: float = 0.04
const HOT_TIME: float = 0.16
const HOT_AMOUNT: float = 0.5
const ACT_TIME: float = 0.2
const MOVING: float = 12.0              ## px/s: faster than this plays the gait
const BOB_SQUASH: float = 0.06
const RING_PULSE: float = 5.0
const SPARKLE_EVERY: float = 0.35
const STAR_COUNT: int = 3
const STAR_ORBIT := Vector2(13.0, 4.0)
const VEIL_OWN: float = 0.45           ## your hidden creature: still clear to you
const VEIL_FOE: float = 0.1            ## a hidden foe: a faint shimmer, so a hidden foe is never quite unfair
const VEIL_RATE: float = 4.0
const ALPHA_GLOW: float = 0.55

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
	add_child(PropSprite.shadow(rec.base_radius() * 2.6))
	ring = _make_ring(rec.base_radius())
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
	_height = float(meta["anchor"][1]) - CreaturePortrait.crop(rec.species_id, rec.shiny).position.y
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


## An alpha glows in its element's light, under its feet and around it.
func add_alpha_glow() -> void:
	var glow := Sprite2D.new()
	glow.texture = LightTex.soft(64)
	glow.material = Fx.glow_material()
	glow.modulate = TamerData.color(element, "light", ALPHA_GLOW)
	glow.position = Vector2(0, -_height * 0.4)
	glow.scale = Vector2.ONE * 1.2
	glow.show_behind_parent = true
	add_child(glow)
	move_child(glow, 0)


## Hidden (tall grass, fog, camouflage): yours turns see-through, a foe all but disappears.
func veil(hidden: bool, own: bool, delta: float) -> void:
	var to: float = (VEIL_OWN if own else VEIL_FOE) if hidden else 1.0
	sprite.modulate.a = move_toward(sprite.modulate.a, to, VEIL_RATE * delta)


## Rears back before a wild attack: a squat and a red glow that build up over `time`.
func windup(time: float) -> void:
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(0.9, 1.12), time * 0.8)
	tw.parallel().tween_property(sprite, "self_modulate", Color(1.6, 0.7, 0.7), time * 0.8)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.05)
	tw.parallel().tween_property(sprite, "self_modulate", Color.WHITE, 0.1)


## Staggered: it reels, wobbling and tinted gold, for `time` seconds.
func reel(time: float) -> void:
	var tw := create_tween()
	var n: int = int(time / 0.25)
	for k: int in n:
		tw.tween_property(sprite, "rotation", 0.18 if k % 2 == 0 else -0.18, 0.25)
	tw.tween_property(sprite, "rotation", 0.0, 0.1)
	var glow := create_tween()
	glow.tween_property(sprite, "self_modulate", Color(1.5, 1.3, 0.7), 0.1)
	glow.tween_interval(time - 0.2)
	glow.tween_property(sprite, "self_modulate", Color.WHITE, 0.1)


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


func _process(_delta: float) -> void:
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
		Fx.burst(self, at, 7, Vector2(10, 40), 0.6, [Pal.c("sun"), Pal.c("gold"), Pal.c("amber", 0.0)], Vector2.UP, 180.0, Vector2(1.5, 2.5))


func _draw_stars() -> void:
	var top: float = -body_height() + 3.0                    # they circle the head
	for k: int in STAR_COUNT:
		var a: float = _t * 0.6 + TAU * k / STAR_COUNT
		var p := (Vector2(cos(a) * STAR_ORBIT.x, top + sin(a) * STAR_ORBIT.y)).round()
		stars.draw_rect(Rect2(p - Vector2(3, 1), Vector2(7, 3)), Pal.c("void"))
		stars.draw_rect(Rect2(p - Vector2(1, 3), Vector2(3, 7)), Pal.c("void"))
		stars.draw_rect(Rect2(p - Vector2(2, 0), Vector2(5, 1)), Pal.c("gold"))
		stars.draw_rect(Rect2(p - Vector2(0, 2), Vector2(1, 5)), Pal.c("gold"))
		stars.draw_rect(Rect2(p, Vector2(1, 1)), Pal.c("sun"))


## Faints: flashes white and fades, rising a little (a knock-out is never gory).
func fade_out(time: float) -> void:
	set_highlight(false)
	stars.visible = false
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "modulate", Color(1.6, 1.6, 1.6, 0.0), time)
	tw.tween_property(sprite, "position:y", sprite.position.y - 10.0, time)
