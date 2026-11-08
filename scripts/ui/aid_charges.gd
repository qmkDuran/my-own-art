class_name AidCharges
extends Control
## Trainer's Aid charges as little tonic flasks lying in a row on top of the heart,
## with their key (from the InputMap's trainer_aid action, F by default) to the left. Full flasks are pink; used ones are dark glass.

## 8×6 flask lying on its side, neck to the right. 'l'/'L' liquid (lit/shaded), 'G' glint,
## 'g' glass at the neck, 'c'/'C' cork (lit/shaded).
const FLASK := [".llll...", "lGllll..", "lllllgcc", "LllllgcC", "LLlll...", ".LLL...."]
const FULL_COLORS := {
	"l": ApolloPalette.PINK, "L": ApolloPalette.MAGENTA, "G": ApolloPalette.WHITE,
	"g": ApolloPalette.SILVER, "c": ApolloPalette.CORK, "C": ApolloPalette.CORK_DARK,
}
const EMPTY_COLORS := {
	"l": ApolloPalette.SLATE, "L": ApolloPalette.DARK, "G": ApolloPalette.STONE,
	"g": ApolloPalette.STONE, "c": ApolloPalette.STONE, "C": ApolloPalette.STONE,
}
## Pixels from one flask's left edge to the next.
const SPACING := 10
const KEY_ACTION := &"trainer_aid"
const KEY_LABEL_TOP_LEFT := Vector2(0, 1)
const FIRST_FLASK_TOP_LEFT := Vector2(7, 0)

var _key_label: String = ""
var _charges: int = 0
var _max_charges: int = 0
var _flask: Dictionary = PixelShape.from_rows(FLASK)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	var aid := PlayerFinder.find_component(self, "TrainerAid") as TrainerAid
	if aid == null:
		return
	aid.charges_changed.connect(_on_charges_changed)
	_on_charges_changed(aid.charges, aid.max_charges)


## Picks up a rebound key.
func _process(_delta: float) -> void:
	var key_label := InputKeyLabel.for_action(KEY_ACTION)
	if key_label != _key_label:
		_key_label = key_label
		queue_redraw()


func _on_charges_changed(charges: int, max_charges: int) -> void:
	_charges = charges
	_max_charges = max_charges
	queue_redraw()


func _draw() -> void:
	if _max_charges <= 0:
		return
	PixelFont.draw_text(self, _key_label, KEY_LABEL_TOP_LEFT, ApolloPalette.GREY, ApolloPalette.OUTLINE)
	for index in _max_charges:
		var colors := FULL_COLORS if index < _charges else EMPTY_COLORS
		var top_left := FIRST_FLASK_TOP_LEFT + Vector2(index * SPACING, 0)
		PixelShape.draw_outlined(self, PixelShape.colored(_flask, colors), top_left, ApolloPalette.OUTLINE)
