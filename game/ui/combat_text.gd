class_name CombatText
extends Control
## Short words above the crosshair when something important lands: a gold "AMBUSH!" with the damage when you
## strike unnoticed, a "CRIT!" on a critical, a red "AMBUSHED!" when the bot gets you. Fades out.

const SHOW_TIME: float = 1.4
const RISE: float = 30.0
const LIFT_FROM_CENTRE: float = 90.0
const LINE_WIDTH: float = 600.0

var _words: String = ""
var _color: Color = HudStyle.INK
var _size: int = HudStyle.FONT_LARGE
var _left: float = 0.0


func setup(player: Creature, bot: Creature) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot.hit_taken.connect(_on_bot_hit)
	player.hit_taken.connect(_on_player_hit)


func _process(delta: float) -> void:
	_left = maxf(0.0, _left - delta)
	queue_redraw()


func _draw() -> void:
	if _left <= 0.0:
		return
	var age: float = 1.0 - _left / SHOW_TIME
	var at := Vector2(size.x * 0.5 - LINE_WIDTH * 0.5, size.y * 0.5 - LIFT_FROM_CENTRE - age * RISE)
	HudStyle.text(self, at, _words, _size, Color(_color, _left / SHOW_TIME), HORIZONTAL_ALIGNMENT_CENTER, LINE_WIDTH)


func _show(words: String, color: Color, font_size: int) -> void:
	_words = words
	_color = color
	_size = font_size
	_left = SHOW_TIME


func _on_bot_hit(amount: float, _attacker: Creature, ambush: bool, kind: String) -> void:
	if ambush:
		_show("AMBUSH!  -%d" % roundi(amount), HudStyle.AMBUSH_COLOR, HudStyle.FONT_LARGE)
	else:
		_show("-%d" % roundi(amount), HudStyle.INK, HudStyle.FONT_MEDIUM)


func _on_player_hit(amount: float, _attacker: Creature, ambush: bool, _kind: String) -> void:
	if ambush:
		_show("AMBUSHED!  -%d" % roundi(amount), HudStyle.SEEN_COLOR, HudStyle.FONT_LARGE)
