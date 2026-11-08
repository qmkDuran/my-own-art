class_name DiscoveryCard
extends Control
## The "NEW CREATURE DISCOVERED" toast: a small, see-through card that gently fades in at
## the top-centre with the creature's portrait, name and element, then slides away.
## (The full-size portrait belongs in the Creature Log, away from the fight.) The game slows down briefly
## (never freezes) so the moment registers while the player keeps control.

const PORTRAIT_SIZE := 32.0          # a 128px portrait at 1:1 screen pixels when the game is scaled 4x
const SHOW_SECONDS := 2.0
## Gap between the top of the screen and the card, in game pixels.
const TOP_MARGIN := 4.0
## How far the card drifts while fading, in game pixels.
const DRIFT := 4.0
const FADE_IN_SECONDS := 0.45
const FADE_OUT_SECONDS := 0.6
const SLOW_MOTION_SCALE := 0.3
const SLOW_MOTION_SECONDS := 0.5     # real seconds

@export var background: Color = Color(0.035, 0.039, 0.078, 0.6)
@export var title_color: Color = Color(0.871, 0.62, 0.255)
@export var name_color: Color = Color(0.906, 0.835, 0.702)
@export var element_color: Color = Color(0.659, 0.792, 0.345)

var _card: PanelContainer
var _portrait: TextureRect
var _title: Label
var _name: Label
var _element: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_card()
	CreatureLog.discovered.connect(_on_discovered)


func _on_discovered(info: Dictionary) -> void:
	_portrait.texture = info.get("portrait")
	_name.text = info["name"]
	_element.text = info["element"]
	_slow_motion()
	_slide_in_and_out()


func _slow_motion() -> void:
	Engine.time_scale = SLOW_MOTION_SCALE
	# A timer that ignores time scale, so it lasts half a real second.
	await get_tree().create_timer(SLOW_MOTION_SECONDS, true, false, true).timeout
	Engine.time_scale = 1.0


## Fades in while drifting down a few pixels, waits, then fades out while drifting back up.
func _slide_in_and_out() -> void:
	_card.reset_size()
	_card.position.x = roundf((size.x - _card.size.x) / 2.0)
	_card.position.y = TOP_MARGIN - DRIFT
	_card.modulate.a = 0.0
	_card.visible = true
	var show := create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	show.set_parallel()
	show.tween_property(_card, "modulate:a", 1.0, FADE_IN_SECONDS)
	show.tween_property(_card, "position:y", TOP_MARGIN, FADE_IN_SECONDS)
	show.chain().tween_interval(SHOW_SECONDS)
	show.chain().tween_property(_card, "modulate:a", 0.0, FADE_OUT_SECONDS)
	show.parallel().tween_property(_card, "position:y", TOP_MARGIN - DRIFT, FADE_OUT_SECONDS)
	show.chain().tween_callback(func() -> void: _card.visible = false)


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(3)
	style.set_content_margin_all(3)
	style.content_margin_right = 6
	_card.add_theme_stylebox_override("panel", style)
	add_child(_card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
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
	_title = _make_label("NEW CREATURE DISCOVERED", 4, title_color)
	_name = _make_label("", 8, name_color)
	_element = _make_label("", 5, element_color)
	for item in [_title, _name, _element]:
		column.add_child(item)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
