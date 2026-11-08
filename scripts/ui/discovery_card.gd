class_name DiscoveryCard
extends Control
## The "NEW CREATURE DISCOVERED" card: slides in from the right with the creature's
## portrait, name and element, then slides away. The game slows down briefly
## (never freezes) so the moment registers while the player keeps control.

const CARD_WIDTH := 132.0
const PORTRAIT_SIZE := 64.0          # a 128px portrait at half size: 2 screen pixels per art pixel at 4x
const SHOW_SECONDS := 2.5
const SLOW_MOTION_SCALE := 0.3
const SLOW_MOTION_SECONDS := 0.5     # real seconds

@export var background: Color = Color(0.075, 0.05, 0.055, 0.86)
@export var border: Color = Color(0.871, 0.62, 0.255, 0.7)
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


func _slide_in_and_out() -> void:
	var resting_x := size.x - CARD_WIDTH - 6.0
	var hidden_x := size.x + 4.0
	_card.position.x = hidden_x
	_card.visible = true
	var slide := create_tween().set_ignore_time_scale(true)
	slide.tween_property(_card, "position:x", resting_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	slide.tween_interval(SHOW_SECONDS)
	slide.tween_property(_card, "position:x", hidden_x, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	slide.tween_callback(func() -> void: _card.visible = false)


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.visible = false
	_card.position = Vector2(0, 22)
	_card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(5)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 3
	_card.add_theme_stylebox_override("panel", style)
	add_child(_card)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_card.add_child(row)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_portrait)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)
	_title = _make_label("NEW CREATURE", 5, title_color)
	_title.text = "NEW CREATURE"
	var subtitle := _make_label("DISCOVERED", 5, title_color)
	subtitle.text = "DISCOVERED"
	_name = _make_label("", 11, name_color)
	_element = _make_label("", 6, element_color)
	for item in [_title, subtitle, _name, _element]:
		column.add_child(item)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
