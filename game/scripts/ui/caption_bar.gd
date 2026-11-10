class_name CaptionBar
extends CanvasLayer
## Screen UI shared by every scene: a white fade, a centred title, the verse caption, and a key hint.
## Caption priority: suppressed > spoken (talk) > forced (an event) > the zone the player stands in.

const VIEW_W: float = 960.0
const SMALL: int = UiText.SMALL
const LARGE: int = UiText.LARGE
const FADE_OUT_RATE: float = 3.0
const FADE_IN_RATE: float = 2.0
const CAPTION_BOX := Vector2(930, 38)      # room for two lines of 16 px text
const CAPTION_LINE: float = 18.0

var fade: ColorRect
var title: Label
var caption: Label
## Optional: returns the zone verse for a position (empty for none).
var zone_resolver: Callable
## When true, zone captions wait until the title has faded away.
var wait_for_title: bool = false
var suppressed: bool = false
var forced: String = ""

var _hint: Label
var _spoken: String = ""
var _shown: String = ""


func _init(caption_y: float, hint: String) -> void:
	fade = ColorRect.new()
	fade.color = Color(1, 1, 1, 0)
	fade.size = Vector2(VIEW_W, 540)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	title = make_label(LARGE, 0.0, "")
	caption = make_label(SMALL, caption_y + CAPTION_LINE - CAPTION_BOX.y, "")
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # long verses wrap onto a second line, growing upward
	caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	caption.position.x = (VIEW_W - CAPTION_BOX.x) / 2.0
	caption.size = CAPTION_BOX
	caption.modulate.a = 0.0
	_hint = make_label(SMALL, 526.0, hint)
	_hint.modulate.a = 0.75


func make_label(font_size: int, y: float, text: String) -> Label:
	return UiText.label(self, font_size, y, text)


## Show the scene title and fade it out after `hold` seconds.
func show_title(text: String, y: float, hold: float = 2.6, out: float = 1.4) -> void:
	title.text = text
	title.position.y = y
	var tw := create_tween()
	tw.tween_interval(hold)
	tw.tween_property(title, "modulate:a", 0.0, out)


## Replace the title with a centred verse (smaller) and fade it in.
func show_verse(text: String, y: float, seconds: float = 0.8) -> Tween:
	title.text = text
	title.label_settings.font_size = SMALL
	title.position.y = y
	var tw := create_tween()
	tw.tween_property(title, "modulate:a", 1.0, seconds)
	return tw


func hide_title(seconds: float) -> void:
	create_tween().tween_property(title, "modulate:a", 0.0, seconds)


## Show a spoken verse (talk) for a few seconds; it overrides zone captions.
func say(text: String, seconds: float) -> void:
	_spoken = text
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if _spoken == text:
			_spoken = "")


func update(pos: Vector2, delta: float) -> void:
	_hint.visible = fade.color.a < 0.3        # no key hint on the white fade screens
	var want: String = _wanted(pos)
	if want != _shown:
		caption.modulate.a = maxf(0.0, caption.modulate.a - delta * FADE_OUT_RATE)
		if caption.modulate.a <= 0.0:
			_shown = want
			caption.text = want
	elif want != "":
		caption.modulate.a = minf(1.0, caption.modulate.a + delta * FADE_IN_RATE)


func _wanted(pos: Vector2) -> String:
	if suppressed:
		return ""
	if _spoken != "":
		return _spoken
	if forced != "":
		return forced
	if wait_for_title and title.modulate.a >= 0.05:
		return ""
	return zone_resolver.call(pos) if zone_resolver.is_valid() else ""


## Zone lookup for data given as [[x, y, w, h, verse], ...] with a fallback verse.
static func zone_lookup(zones: Array, fallback: String = "") -> Callable:
	return func(pos: Vector2) -> String:
		for z: Array in zones:
			if SceneData.rect(z).has_point(pos):
				return z[4]
		return fallback
