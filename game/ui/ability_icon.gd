class_name AbilityIcon
extends Control
## One move's icon: a simple glyph for its kind, its key, its name, a dark sweep while it cools down (with seconds
## left), a bright edge while it is winding up, and dimmed when it cannot be used here (no soft soil to burrow ...).

const ICON_SIZE: float = 64.0
const LABEL_SPACE: float = 26.0
## Move names are longer than the icon is wide; the slot is this wide so they fit underneath.
const SLOT_WIDTH: float = 112.0
const SWEEP_POINTS: int = 32
const SWEEP_COLOR: Color = Color(0, 0, 0, 0.62)
const ACTIVE_EDGE: float = 4.0
const GLYPH_WIDTH: float = 3.0
const GLYPH_SCALE: float = 0.3
const DIGIT_DROP: float = 0.35
const TEXT_INSET: float = 6.0

var _ability: Ability
var _key: String
var _title: String
var _tint: Color
var _glyph: Callable


func setup(ability: Ability, key: String, title: String, tint: Color, glyph: Callable) -> void:
	_ability = ability
	_key = key
	_title = title
	_tint = tint
	_glyph = glyph
	custom_minimum_size = Vector2(SLOT_WIDTH, ICON_SIZE + LABEL_SPACE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var box := Rect2(Vector2((SLOT_WIDTH - ICON_SIZE) * 0.5, 0), Vector2(ICON_SIZE, ICON_SIZE))
	HudStyle.panel(self, box)
	var usable: bool = _ability.is_ready() and (not _ability is Move or (_ability as Move).usable())
	_glyph.call(self, box.get_center(), ICON_SIZE * GLYPH_SCALE, _tint if usable else HudStyle.INK_DIM, GLYPH_WIDTH)
	if _ability.cooldown_left > 0.0:
		_draw_sweep(box, _ability.cooldown_share())
		var digits_at := Vector2(0, box.get_center().y + HudStyle.FONT_MEDIUM * DIGIT_DROP)
		HudStyle.text(self, digits_at, "%.1f" % _ability.cooldown_left, HudStyle.FONT_MEDIUM, HudStyle.INK,
				HORIZONTAL_ALIGNMENT_CENTER, SLOT_WIDTH)
	if _ability.busy():
		draw_rect(box, _tint, false, ACTIVE_EDGE)
	var key_at := Vector2(box.position.x + TEXT_INSET, HudStyle.FONT_SMALL)
	HudStyle.text(self, key_at, _key, HudStyle.FONT_SMALL, HudStyle.INK_DIM, HORIZONTAL_ALIGNMENT_LEFT, ICON_SIZE)
	HudStyle.text(self, Vector2(0, ICON_SIZE + LABEL_SPACE - TEXT_INSET), _title, HudStyle.FONT_SMALL, HudStyle.INK,
			HORIZONTAL_ALIGNMENT_CENTER, SLOT_WIDTH)


## A clock-hand sweep covering the share of the cooldown still to go.
func _draw_sweep(box: Rect2, share: float) -> void:
	var centre: Vector2 = box.get_center()
	var reach: float = ICON_SIZE
	var points := PackedVector2Array([centre])
	for k: int in SWEEP_POINTS + 1:
		var angle: float = -PI * 0.5 + TAU * share * k / SWEEP_POINTS
		var point: Vector2 = centre + Vector2.from_angle(angle) * reach
		points.append(point.clamp(box.position, box.end))
	draw_colored_polygon(points, SWEEP_COLOR)
