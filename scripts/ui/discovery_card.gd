class_name DiscoveryCard
extends Control
## The "NEW CREATURE DISCOVERED" toast: a small, see-through card that gently fades in at
## the top-centre with the creature's portrait, name and element, then slides away. It
## rests below any other top-centre card already showing (TopCentreStack).
## (The full-size portrait belongs in the Creature Log, away from the fight.) The game slows down briefly
## (never freezes) so the moment registers while the player keeps control.
## A HudCard: the Ember Tree's card style and Monogram font, laid out in card pixels
## (UI pixels) and shown scaled to the game (HudCard).

const GROUP := "discovery_card"
## Nodes in this group are told through `on_discovery_card_changed()` whenever a card shows
## or hides (e.g. the boss bar makes way for it).
const WATCHERS_GROUP := "discovery_card_watchers"
## A 128 px portrait shown 1:1 in a 1080p window (2 window pixels per card pixel).
const PORTRAIT_SIZE := 64.0
## Gap between the portrait and the words, in card pixels.
const PORTRAIT_GAP := 8
## Gap between the top of the screen and the card, in game pixels.
const TOP_MARGIN := 4.0
const FADE_IN_SECONDS := 0.45
const SLOW_MOTION_SCALE := 0.3
const SLOW_MOTION_SECONDS := 0.5     # real seconds

@export var title_color: Color = EmberTreePalette.ORANGE
@export var name_color: Color = EmberTreePalette.CREAM
@export var element_color: Color = ApolloPalette.GREEN_LIGHT

var _card: PanelContainer
var _portrait: TextureRect
var _title: Label
var _name: Label
var _element: Label
## Species met while a card is still showing (e.g. two new kinds noticed together) wait here.
var _waiting: Array[Dictionary] = []
## True during the slow motion, so a card freed mid-way (the zone changed) still ends it.
var _is_slowing_time: bool = false


## Whether a discovery card is up on the HUD of `asker`'s level (others make way for it).
static func is_showing_on(asker: Node) -> bool:
	for card: DiscoveryCard in asker.get_tree().get_nodes_in_group(GROUP):
		if card._card.visible:
			return true
	return false


func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_card()
	CreatureLog.discovered.connect(_on_discovered)


func _exit_tree() -> void:
	_end_slow_motion()


func _on_discovered(info: Dictionary) -> void:
	if _card.visible:
		_waiting.append(info)
	else:
		_announce(info)


func _announce(info: Dictionary) -> void:
	_show_picture(info)
	_name.text = info["name"]
	_element.text = info["element"]
	_slow_motion()
	_slide_in_and_out()


## The painted portrait; for a species without one yet, its sprite scaled up (crisp, since
## the picture is drawn with nearest filtering); with neither, the card shows only words.
func _show_picture(info: Dictionary) -> void:
	var picture: Texture2D = info.get("portrait")
	if picture == null:
		picture = info.get("sprite")
	_portrait.texture = picture
	_portrait.visible = picture != null


func _slow_motion() -> void:
	_is_slowing_time = true
	Engine.time_scale = SLOW_MOTION_SCALE
	await Wait.seconds(self, SLOW_MOTION_SECONDS, true)
	_end_slow_motion()


func _end_slow_motion() -> void:
	if _is_slowing_time:
		_is_slowing_time = false
		Engine.time_scale = 1.0


## Fades in while drifting down a few pixels, waits, then fades out while drifting back up.
func _slide_in_and_out() -> void:
	_card.reset_size()
	var tween := TopCentreStack.show_card(_card, size.x, TOP_MARGIN, FADE_IN_SECONDS, true)
	tween.chain().tween_callback(_finish_showing)
	_tell_watchers()


func _finish_showing() -> void:
	_card.visible = false
	if _waiting.is_empty():
		_tell_watchers()
	else:
		_announce(_waiting.pop_front())


func _tell_watchers() -> void:
	get_tree().call_group(WATCHERS_GROUP, "on_discovery_card_changed")


func _build_card() -> void:
	_card = HudCard.make()
	_card.visible = false
	add_child(_card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PORTRAIT_GAP)
	_card.add_child(row)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_portrait)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	row.add_child(column)
	_title = UiLabel.make(EmberTreeFonts.TEXT_SIZE, title_color, "NEW CREATURE DISCOVERED")
	_name = UiLabel.make(EmberTreeFonts.LARGE_SIZE, name_color)
	_element = UiLabel.make(EmberTreeFonts.TEXT_SIZE, element_color)
	for item: Label in [_title, _name, _element]:
		column.add_child(item)

