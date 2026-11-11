class_name TimingRing
extends Node2D
## The timing press: a ring shrinks onto a target circle; press accept (or click) as it lands.
## Perfect inside the inner window, Good near it, otherwise a miss (just normal damage). Never required.

signal graded(grade: String)

const START_R: float = 40.0
const TARGET_R: float = 13.0
const DURATION: float = 0.85
const PERFECT_BAND: float = 2.5
const GOOD_BAND: float = 7.0
const LABEL_TIME: float = 0.45
const RING_W: float = 2.0
const TEXTS: Dictionary = {"perfect": "Perfect!", "good": "Good", "miss": ""}
const ACCENTS: Dictionary = {"attack": "ember3", "defend": "water3", "gentle": "rose2"}
const HINTS: Dictionary = {"attack": "STRIKE!", "defend": "BRACE!", "gentle": "GENTLY"}

## Tests and screenshot runs: a grade to give at once ("" = wait for the player), or hold the ring still.
static var autopilot: String = ""
static var hold_at: float = -1.0

var mode: String = "attack"
var _t: float = 0.0
var _done: bool = true
var _grade_label: Label


func _ready() -> void:
	_grade_label = UiKit.label("", "cream")
	_grade_label.add_theme_color_override("font_outline_color", UiKit.c("ink"))
	_grade_label.add_theme_constant_override("outline_size", 3)
	_grade_label.position = Vector2(-20, -TARGET_R - 22)
	_grade_label.custom_minimum_size = Vector2(40, 0)
	_grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_grade_label)
	hide()


## Runs one press at a point on screen; returns "perfect", "good" or "miss".
func run(at: Vector2, kind: String) -> String:
	position = at
	mode = kind
	_t = 0.0
	_done = false
	_grade_label.text = ""
	show()
	var grade: String = autopilot
	if autopilot != "":
		await get_tree().process_frame
		_finish(autopilot)
	else:
		grade = await graded
	await _show_grade(grade)
	return grade


func current_radius() -> float:
	return lerpf(START_R, 0.0, _t / DURATION)


func _process(delta: float) -> void:
	if _done:
		return
	if hold_at >= 0.0:
		_t = hold_at * DURATION
	else:
		_t += delta
	queue_redraw()
	if current_radius() < TARGET_R - GOOD_BAND:
		_finish("miss")


func _unhandled_input(ev: InputEvent) -> void:
	if _done:
		return
	var press: bool = ev.is_action_pressed("accept") or UiKit.is_click(ev)
	if press:
		get_viewport().set_input_as_handled()
		_finish(grade_for(current_radius()))


static func grade_for(radius: float) -> String:
	var off: float = absf(radius - TARGET_R)
	if off <= PERFECT_BAND:
		return "perfect"
	return "good" if off <= GOOD_BAND else "miss"


func _finish(grade: String) -> void:
	if _done:
		return
	_done = true
	Audio.sfx("timing_" + grade)
	graded.emit(grade)


func _show_grade(grade: String) -> void:
	_grade_label.text = TEXTS[grade]
	_grade_label.add_theme_color_override("font_color", UiKit.c("sun" if grade == "perfect" else "cream"))
	queue_redraw()
	await Game.wait(LABEL_TIME if grade != "miss" else 0.15)
	hide()


func _draw() -> void:
	if _done:
		return
	var accent: String = String(ACCENTS[mode])
	draw_arc(Vector2.ZERO, TARGET_R + GOOD_BAND, 0, TAU, 48, UiKit.c("mist"), 1.0, false)
	draw_arc(Vector2.ZERO, TARGET_R, 0, TAU, 40, UiKit.c("cream"), RING_W, false)
	draw_arc(Vector2.ZERO, TARGET_R, 0, TAU, 40, UiKit.c("ink"), 1.0, false)
	draw_arc(Vector2.ZERO, current_radius(), 0, TAU, 48, UiKit.c(accent), RING_W, false)
	var hint: String = String(HINTS[mode])
	var w: float = UiKit.text_width(hint, true)
	draw_string(UiKit.small_font(), Vector2(-w / 2, TARGET_R + 13), hint, HORIZONTAL_ALIGNMENT_LEFT, -1,
		UiKit.SMALL_SIZE, UiKit.c("ink"))
	draw_string(UiKit.small_font(), Vector2(-w / 2, TARGET_R + 12), hint, HORIZONTAL_ALIGNMENT_LEFT, -1,
		UiKit.SMALL_SIZE, UiKit.c("cream"))
