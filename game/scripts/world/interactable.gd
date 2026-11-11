class_name Interactable
extends Node2D
## Something the Lamplighter can use by clicking it (he walks over first): its sprite, a name that shows on hover,
## and a reach. Subclasses decide what using it does.

const REACH: float = 46.0
const NAME_Y: float = 8.0
const HOVER_PAD: float = 4.0

var kind: String
var prop: Dictionary
var sprite: Sprite2D
var title: String = ""
var hovered: bool = false
var _label: Label


func setup(p: Dictionary) -> Interactable:
	prop = p
	kind = String(p["kind"])
	position = p["pos"]
	return self


func _ready() -> void:
	add_to_group("interactables")
	sprite = make_sprite()
	if sprite != null:
		add_child(sprite)
	_label = Label.new()
	_label.label_settings = UiDraw.label_settings(UiDraw.BODY, UiDraw.GOLD)
	_label.text = title
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200, 14)
	_label.position = Vector2(-100, NAME_Y)
	_label.visible = false
	Overlay.follower(self).add_child(_label)


func make_sprite() -> Sprite2D:
	var s: Sprite2D = PropSprite.make(kind) if GameData.props.has(kind) else null
	if s != null and (prop["foot"] as Rect2).size.x > 0.0:
		s.add_child(PropSprite.shadow((prop["foot"] as Rect2).size.x * 1.2))
	return s


## Screen-independent pick area: the sprite's box in world space.
func pick_rect() -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2(global_position - Vector2(12, 24), Vector2(24, 28))
	var w: float = sprite.texture.get_width() / float(sprite.hframes)
	var h: float = sprite.texture.get_height() / float(sprite.vframes)
	return Rect2(global_position + Vector2(-w / 2.0, -h), Vector2(w, h)).grow(HOVER_PAD)


func set_hover(on: bool) -> void:
	hovered = on
	_label.text = title
	_label.visible = on and title != ""
	if sprite != null:
		sprite.self_modulate = Color(1.25, 1.2, 1.1) if on else Color.WHITE


func use(_g: Game) -> void:
	pass


func stand_point() -> Vector2:
	return global_position + Vector2(0, 18)
