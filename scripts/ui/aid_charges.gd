class_name AidCharges
extends Control
## Trainer's Aid charges as little tonic flasks lying in a row on top of the heart,
## with their key (from the InputMap's trainer_aid action, F by default) to the left. Full flasks are pink; used ones are dark glass.
## A flask just used blinks out; one just refilled (from a berry) pops in with a flash and a hop.

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
## A used flask blinks full/empty for this long, switching every BLINK_STEP_SECONDS.
const SPENT_BLINK_SECONDS := 0.3
const BLINK_STEP_SECONDS := 0.06
## A refilled flask hops up a pixel for this long, shown pale white for the first third.
const REFILL_POP_SECONDS := 0.16
const REFILL_FLASH_SHARE := 0.34
const FLASH_COLORS := {
	"l": ApolloPalette.WHITE, "L": ApolloPalette.SILVER, "G": ApolloPalette.WHITE,
	"g": ApolloPalette.WHITE, "c": ApolloPalette.SILVER, "C": ApolloPalette.SILVER,
}

var _key_label: String = ""
var _charges: int = 0
var _max_charges: int = 0
var _flask: Dictionary = PixelShape.from_rows(FLASK)
var _spent_blink := HudMotion.new(SPENT_BLINK_SECONDS)
var _refill_pop := HudMotion.new(REFILL_POP_SECONDS)
## Which flask the blink or the pop is playing on.
var _spent_index: int = -1
var _refilled_index: int = -1
## Rebinds the flasks when another creature becomes the player (a team swap).
var _player_watch := PlayerWatch.new()
var _bound_aid: TrainerAid


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Picks up a rebound key (and a swapped-in creature), and moves the blink and the pop on.
func _process(delta: float) -> void:
	if _player_watch.has_changed(self):
		_bind_to_player_aid()
	var key_label := InputKeyLabel.for_action(KEY_ACTION)
	var is_moving := _spent_blink.advance(delta)
	is_moving = _refill_pop.advance(delta) or is_moving
	if key_label != _key_label or is_moving:
		_key_label = key_label
		queue_redraw()


## Shows the player's Trainer's Aid charges; a creature without the Aid hides the flasks.
func _bind_to_player_aid() -> void:
	if is_instance_valid(_bound_aid):
		_bound_aid.charges_changed.disconnect(_on_charges_changed)
	_bound_aid = PlayerFinder.find_component(self, "TrainerAid") as TrainerAid
	_charges = 0
	_max_charges = 0
	_spent_index = -1
	_refilled_index = -1
	if _bound_aid != null:
		_bound_aid.charges_changed.connect(_on_charges_changed)
		_on_charges_changed(_bound_aid.charges, _bound_aid.max_charges)
	queue_redraw()


func _on_charges_changed(charges: int, max_charges: int) -> void:
	if max_charges == _max_charges and charges < _charges:
		_spent_index = charges
		_spent_blink.start()
	elif max_charges == _max_charges and charges > _charges:
		_refilled_index = charges - 1
		_refill_pop.start()
	_charges = charges
	_max_charges = max_charges
	queue_redraw()


func _draw() -> void:
	if _max_charges <= 0:
		return
	PixelFont.draw_text(self, _key_label, KEY_LABEL_TOP_LEFT, ApolloPalette.GREY, ApolloPalette.OUTLINE)
	for index in _max_charges:
		var top_left := FIRST_FLASK_TOP_LEFT + Vector2(index * SPACING, 0)
		if index == _refilled_index:
			top_left += _refill_pop.bounce()
		PixelShape.draw_outlined(self, PixelShape.colored(_flask, _flask_colors(index)), top_left, ApolloPalette.OUTLINE)


## Full or empty, unless the flask is blinking out or popping in.
func _flask_colors(index: int) -> Dictionary:
	if index == _spent_index and _spent_blink.blink(BLINK_STEP_SECONDS):
		return FULL_COLORS
	if index == _refilled_index and _refill_pop.is_in_first(REFILL_FLASH_SHARE):
		return FLASH_COLORS
	return FULL_COLORS if index < _charges else EMPTY_COLORS
