class_name StealthEye
extends Control
## The stealth eye: what the bot knows about you, at a glance. Closed green eye: HIDDEN (it has no idea where you
## are). Half-open amber eye: HEARD (it has a clue and is looking). Wide-open red eye: SEEN. Under it: whether you
## are in cover, and a gold AMBUSH READY when your next bite or spit would be an ambush.

const EYE_SIZE: Vector2 = Vector2(110, 56)
const PANEL_SIZE: Vector2 = Vector2(190, 150)
const OUTLINE_POINTS: int = 24
const LINE_WIDTH: float = 4.0
const IRIS_SHARE: float = 0.36
const PUPIL_SHARE: float = 0.45
const LASH_COUNT: int = 5
const LASH_LENGTH: float = 10.0
const EYE_TOP: float = 14.0
const LOWER_LID_MIN: float = 0.35
const LABELS: Array[String] = ["HIDDEN", "HEARD", "SEEN"]
const COLORS: Array[Color] = [HudStyle.HIDDEN_COLOR, HudStyle.HEARD_COLOR, HudStyle.SEEN_COLOR]
const OPENNESS: Array[float] = [0.0, 0.45, 1.0]

var _brain: BotBrain
var _player: Creature


func setup(brain: BotBrain, player: Creature) -> void:
	_brain = brain
	_player = player
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	HudStyle.panel(self, Rect2(Vector2.ZERO, PANEL_SIZE))
	var level: int = _brain.alert()
	var centre := Vector2(PANEL_SIZE.x * 0.5, EYE_SIZE.y * 0.5 + EYE_TOP)
	_draw_eye(centre, OPENNESS[level], COLORS[level])
	var line: float = centre.y + EYE_SIZE.y * 0.5 + HudStyle.FONT_LARGE
	HudStyle.text(self, Vector2(0, line), LABELS[level], HudStyle.FONT_LARGE, COLORS[level],
			HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x)
	line += HudStyle.FONT_SMALL + HudStyle.EDGE_WIDTH * 2.0
	HudStyle.text(self, Vector2(0, line), _cover_words(), HudStyle.FONT_SMALL, HudStyle.INK_DIM,
			HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x)
	if _player.ambush_ready() and level != BotBrain.Alert.SEEN:
		line += HudStyle.FONT_SMALL + HudStyle.EDGE_WIDTH * 2.0
		HudStyle.text(self, Vector2(0, line), "AMBUSH READY", HudStyle.FONT_SMALL, HudStyle.AMBUSH_COLOR,
				HORIZONTAL_ALIGNMENT_CENTER, PANEL_SIZE.x)


func _cover_words() -> String:
	if _player.stealth.is_hidden():
		return "in cover"
	return "revealed" if _player.stealth.in_cover() else "in the open"


## An almond eye; openness 0 draws a closed lid with lashes, 1 a wide eye with iris and pupil.
func _draw_eye(centre: Vector2, openness: float, color: Color) -> void:
	var half: Vector2 = EYE_SIZE * 0.5
	var lower := PackedVector2Array()
	var upper := PackedVector2Array()
	for k: int in OUTLINE_POINTS + 1:
		var t: float = float(k) / OUTLINE_POINTS
		var x: float = lerpf(-half.x, half.x, t)
		var bulge: float = sin(t * PI) * half.y
		lower.append(centre + Vector2(x, bulge * maxf(openness, LOWER_LID_MIN)))
		upper.append(centre + Vector2(x, -bulge * openness))
	draw_polyline(lower, color, LINE_WIDTH, true)
	if openness <= 0.0:
		for k: int in LASH_COUNT:
			var at: Vector2 = lower[int((k + 1) * OUTLINE_POINTS / (LASH_COUNT + 1))]
			draw_line(at, at + (at - centre).normalized() * LASH_LENGTH, color, LINE_WIDTH * 0.5, true)
		return
	draw_polyline(upper, color, LINE_WIDTH, true)
	var iris: float = half.y * IRIS_SHARE * (1.0 + openness)
	draw_circle(centre, iris, color)
	draw_circle(centre, iris * PUPIL_SHARE, HudStyle.SHADOW)
