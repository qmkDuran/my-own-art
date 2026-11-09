class_name BossDefeatedBanner
extends Control
## The short victory card at the top-centre, e.g. "WARDEN CAPTAIN DEFEATED": a HudCard in the
## discovery card's style that fades in, stays for a couple of seconds and drifts away.

const SHOW_SECONDS := 2.0
## Gap between the top of the screen and the card, in game pixels.
const TOP_MARGIN := 10.0
## How far the card drifts while fading, in game pixels.
const DRIFT := 4.0
const FADE_IN_SECONDS := 0.35
const FADE_OUT_SECONDS := 0.6

@export var text_color: Color = EmberTreePalette.ORANGE

var _card: PanelContainer
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = HudCard.make()
	_card.visible = false
	add_child(_card)
	_label = UiLabel.make(EmberTreeFonts.LARGE_SIZE, text_color)
	_card.add_child(_label)


func announce(text: String) -> void:
	_label.text = text
	_card.reset_size()
	_card.position.x = roundf((get_viewport_rect().size.x - HudCard.size_on_screen(_card).x) / 2.0)
	_card.position.y = TOP_MARGIN - DRIFT
	_card.modulate.a = 0.0
	_card.visible = true
	var show := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	show.set_parallel()
	show.tween_property(_card, "modulate:a", 1.0, FADE_IN_SECONDS)
	show.tween_property(_card, "position:y", TOP_MARGIN, FADE_IN_SECONDS)
	show.chain().tween_interval(SHOW_SECONDS)
	show.chain().tween_property(_card, "modulate:a", 0.0, FADE_OUT_SECONDS)
	show.parallel().tween_property(_card, "position:y", TOP_MARGIN - DRIFT, FADE_OUT_SECONDS)
	show.chain().tween_callback(_card.hide)
