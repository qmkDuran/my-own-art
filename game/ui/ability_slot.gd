class_name AbilitySlot
extends Control
## One ability on the HUD: a rounded dark tile with a code-drawn glyph in the ability's colour (a flame bolt, a
## beam, a bomb, a hexagonal ward, a blink chevron, a sun), a clockwise sweep that darkens it while it cools down,
## a fill ring (the heavy's charge, the super's meter, which pulses when full) and its key below.

const SEGMENTS: int = 32
const KEY_GAP: float = 4.0
const RING: float = 3.0
const CORNER: int = 10
const PULSE_LOW: float = 0.6

var ability: String = ""
var key: String = ""
## 0 ready .. 1 just used.
var cooldown: float = 0.0
## 0..1: the heavy's charge or the super's meter (drawn as a ring), -1 when unused.
var fill: float = -1.0
var full: bool = false
var _clock: float = 0.0


func setup(ability_name: String, key_label: String) -> void:
	name = ability_name.capitalize() + "Slot"
	ability = ability_name
	key = key_label
	var size_px: float = Tuning.f("combat_hud", "slot_size")
	custom_minimum_size = Vector2(size_px, size_px + Tuning.f("combat_hud", "key_font") + KEY_GAP)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var side: float = Tuning.f("combat_hud", "slot_size")
	var tile := Rect2(Vector2.ZERO, Vector2(side, side))
	var box: StyleBoxFlat = UiStyle.panel_box()
	box.set_corner_radius_all(CORNER)
	draw_style_box(box, tile)
	var centre: Vector2 = tile.get_center()
	HudGlyphs.draw(self, ability, centre, side * Tuning.f("combat_hud", "glyph"), colour_of("glyph_" + ability))
	if cooldown > 0.0:
		_sweep(centre, side * 0.5, cooldown, colour_of("cooldown"))
	if fill >= 0.0:
		var ring: Color = colour_of("meter_full" if full else "meter")
		if full:
			ring.a = PULSE_LOW + (1.0 - PULSE_LOW) * sin(_clock * Tuning.f("combat_hud", "full_pulse") * PI)
		draw_arc(centre, side * 0.5 - RING, -PI * 0.5, -PI * 0.5 + TAU * fill, SEGMENTS, ring, RING, true)
	var font: Font = get_theme_default_font()
	var size: int = Tuning.i("combat_hud", "key_font")
	var width: float = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2((side - width) * 0.5, side + KEY_GAP + size), key, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
		UiStyle.TEXT)


## A dark pie over the part of the cooldown still to run (clockwise from the top).
func _sweep(centre: Vector2, radius: float, share: float, colour: Color) -> void:
	var points := PackedVector2Array([centre])
	var steps: int = maxi(2, int(SEGMENTS * share))
	for index: int in steps + 1:
		var angle: float = -PI * 0.5 + TAU * (1.0 - share) + TAU * share * index / steps
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, colour)


static func colour_of(key_name: String) -> Color:
	return Tuning.color(Tuning.doc("tuning")["combat_hud"]["colors"][key_name])
