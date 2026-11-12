class_name TamerFx
extends RefCounted
## Element-coloured effects for creature moves, on top of Lanternfall's Fx kit: a sweeping slash crescent, an area
## blast, a ward bubble, dash streaks, floating words ("Strong hit!", "Lv 6!") and the celebration burst. All
## additive and unlit (abilities shine), short so fights stay readable.

const SLASH_TIME: float = 0.16
const SLASH_WIDTH: float = 7.0
const WORD_RISE: float = 10.0
const WORD_TIME: float = 0.9
const WORD_HEAD: float = 64.0
const BLAST_TIME: float = 0.3
const WARD_ALPHA: float = 0.5
const LANE: float = 17.0                ## words near each other stack in lanes this far apart
const LANE_NEAR := Vector2(110.0, 80.0)

static var _words: Array = []           ## [position, label] of words still on screen, for lanes


static func layer() -> Node2D:
	return TamerGame.current.fx_layer


## A crescent that sweeps across `arc_deg` toward `dir`, in the element's colours.
static func slash(at: Vector2, dir: Vector2, reach: float, arc_deg: float, element: String) -> void:
	var n := Node2D.new()
	n.position = at
	n.rotation = dir.angle()
	n.material = Fx.glow_material()
	n.z_index = Fx.FX_Z
	var half: float = deg_to_rad(arc_deg) * 0.5
	var state: Dictionary = {"k": 0.0}
	n.draw.connect(func() -> void:
		var k: float = float(state["k"])
		var a0: float = -half
		var a1: float = lerpf(-half, half, minf(1.0, k * 1.6))
		var fade: float = 1.0 - maxf(0.0, k - 0.5) * 2.0
		n.draw_arc(Vector2.ZERO, reach * 0.8, a0, a1, 18, TamerData.color(element, "dark", fade), SLASH_WIDTH * 1.6)
		n.draw_arc(Vector2.ZERO, reach * 0.8, a0, a1, 18, TamerData.color(element, "core", fade), SLASH_WIDTH)
		n.draw_arc(Vector2.ZERO, reach * 0.8 + 2.0, a0, a1, 18, Color(Pal.c("sun"), fade), 2.0))
	layer().add_child(n)
	var tw := n.create_tween()
	tw.tween_method(func(v: float) -> void:
		state["k"] = v
		n.queue_redraw(), 0.0, 1.0, SLASH_TIME)
	tw.tween_callback(n.queue_free)


## An area blast: a ring racing out, a halo, sparks and a ground flash.
static func blast(at: Vector2, radius: float, element: String, big: bool = false) -> void:
	var fx: Node2D = layer()
	Fx.ring(fx, at, radius * 0.3, radius * 1.1, TamerData.color(element, "core"), BLAST_TIME)
	Fx.ring(fx, at, radius * 0.1, radius * 0.8, TamerData.color(element, "light"), BLAST_TIME * 0.8)
	Fx.halo(fx, at + Vector2(0, -8), radius * 1.4, TamerData.color(element, "core", 0.9), BLAST_TIME)
	Fx.burst(fx, at + Vector2(0, -6), 26 if big else 16, Vector2(80, radius * 3.0), 0.45, TamerData.sparks(element), Vector2.UP, 180.0, Vector2(1.2, 2.2))
	Fx.flash(fx, at, radius * 2.4, TamerData.color(element), 2.5, 0.35)
	if big:
		Fx.core(fx, at + Vector2(0, -10), radius * 0.6, 0.08)
		CameraRig.shake(0.35)


## A streak along a dash, from `from` to `to`.
static func streak(from: Vector2, to: Vector2, element: String) -> void:
	var line := Line2D.new()
	line.points = PackedVector2Array([from + Vector2(0, -8), to + Vector2(0, -8)])
	line.width = 10.0
	line.default_color = TamerData.color(element, "core", 0.8)
	line.material = Fx.glow_material()
	line.z_index = Fx.FX_Z
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	layer().add_child(line)
	var tw := line.create_tween().set_parallel()
	tw.tween_property(line, "width", 1.0, 0.25)
	tw.tween_property(line, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(line.queue_free)


## A ward bubble that follows `who` for `time` seconds.
static func ward(who: Node2D, radius: float, element: String, time: float) -> void:
	var s := Sprite2D.new()
	s.texture = LightTex.ring()
	s.material = Fx.glow_material()
	s.modulate = TamerData.color(element, "light", WARD_ALPHA)
	s.scale = Vector2.ONE * radius * 2.0 / 64.0
	s.position = Vector2(0, -12)
	s.z_index = Fx.FX_Z
	who.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", WARD_ALPHA * 0.5, time * 0.85)
	tw.tween_property(s, "modulate:a", 0.0, time * 0.15)
	tw.tween_callback(s.queue_free)


## A word that pops over a creature ("Strong hit!", "STAGGERED!", "Lv 6!").
static func word(at: Vector2, text: String, col: Color, size: int = UiDraw.BODY) -> void:
	if Overlay.layer == null:
		return
	var l := Label.new()
	var ls := UiDraw.label_settings(size, col)
	ls.outline_size = 4
	l.label_settings = ls
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(160, size + 8)
	l.pivot_offset = l.size / 2.0
	l.position = at + Vector2(-80, -WORD_HEAD - _lane(at, l) * LANE)
	l.scale = Vector2.ONE * 1.5
	Overlay.layer.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - WORD_RISE, WORD_TIME).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, WORD_TIME * 0.4).set_delay(WORD_TIME * 0.6)
	tw.chain().tween_callback(l.queue_free)


## How many recent words are still showing near `at` (this one goes above them).
## Lanes are taken by labels still on screen (hit-stop slows their fade, so time alone is not enough); the lowest
## free lane is used.
static func _lane(at: Vector2, label: Label) -> int:
	_words = _words.filter(func(w: Array) -> bool: return is_instance_valid(w[1]))
	var taken: Array[int] = []
	for w: Array in _words:
		if absf((w[0] as Vector2).x - at.x) < LANE_NEAR.x and absf((w[0] as Vector2).y - at.y) < LANE_NEAR.y:
			taken.append(int(w[2]))
	var lane: int = 0
	while taken.has(lane):
		lane += 1
	_words.append([at, label, lane])
	return lane


## Bond up: hearts of light rise around the creature and the trainer, with a chime.
static func celebrate(who: Node2D, element: String) -> void:
	var fx: Node2D = layer()
	var at: Vector2 = who.global_position + Vector2(0, -16)
	Fx.burst(fx, at, 30, Vector2(40, 140), 0.9, [Pal.c("sun"), Pal.c("rose"), Pal.c("blood", 0.0)], Vector2.UP, 70.0, Vector2(1.5, 2.5))
	Fx.burst(fx, at, 20, Vector2(60, 160), 0.7, TamerData.sparks(element), Vector2.UP, 180.0, Vector2(1.0, 2.0))
	Fx.ring(fx, who.global_position, 10.0, 90.0, Pal.c("rose"), 0.5)
	Fx.flash(fx, who.global_position, 200.0, Pal.c("rose"), 2.5, 0.6)
	Audio.sfx("level_up", -4.0, 1.25)
