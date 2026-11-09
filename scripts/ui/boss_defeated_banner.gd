class_name BossDefeatedBanner
extends Control
## The short victory card at the top-centre, e.g. "WARDEN CAPTAIN DEFEATED": a HudCard in the
## discovery card's style that fades in, stays for a couple of seconds and drifts away.
## It rests below any other top-centre card already showing (TopCentreStack).

## Gap between the top of the screen and the card, in game pixels.
const TOP_MARGIN := 10.0
const FADE_IN_SECONDS := 0.35
## Room kept between the card and the screen's sides, in game pixels. Text too long for the
## big font within it drops to the normal size instead of running off the screen.
const SIDE_MARGIN := 8.0
## The text is all capitals, which sit low in Monogram's line (room above them is for
## accents, below for descenders): a little less padding on top centres them in the card.
const CAPITALS_LIFT := 2

@export var text_color: Color = EmberTreePalette.ORANGE

var _card: PanelContainer
var _label: Label
## The card's running fade, cut short when a new announcement comes in.
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = HudCard.make()
	_card.visible = false
	var style := _card.get_theme_stylebox("panel") as PixelPanelStyle
	style.content_margin_top -= CAPITALS_LIFT
	style.content_margin_bottom += CAPITALS_LIFT
	add_child(_card)
	_label = UiLabel.make(EmberTreeFonts.LARGE_SIZE, text_color)
	_card.add_child(_label)


func announce(text: String) -> void:
	_label.text = text
	_label.add_theme_font_size_override("font_size", EmberTreeFonts.LARGE_SIZE)
	_card.reset_size()
	if HudCard.size_on_screen(_card).x > get_viewport_rect().size.x - SIDE_MARGIN * 2.0:
		_label.add_theme_font_size_override("font_size", EmberTreeFonts.TEXT_SIZE)
		_card.reset_size()
	if _tween != null:
		_tween.kill()
	_tween = TopCentreStack.show_card(_card, get_viewport_rect().size.x, TOP_MARGIN, FADE_IN_SECONDS)
	_tween.chain().tween_callback(_card.hide)
