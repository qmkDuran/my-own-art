class_name GroundItem
extends Node2D
## A dropped item: its icon on the ground (with a coloured beam for magic and better) and its name in rarity
## colour. Taken by clicking the name — the Lamplighter walks there. Labels never overlap (LabelStack); Alt hides
## them.

const ICON: int = 24
const LABEL_H: float = 13.0
const LABEL_Y: float = -30.0
const BEAM_ENERGY: float = 0.9
const BEAM_RANGE: float = 40.0

var item: Dictionary
var label: Label
var stack_lift: float = 0.0


static func spawn(parent: Node, at: Vector2, it: Dictionary) -> GroundItem:
	var g := GroundItem.new()
	g.item = it
	g.position = at
	parent.add_child(g)
	return g


func _ready() -> void:
	add_to_group("ground_items")
	var icon := Sprite2D.new()
	icon.texture = PropSprite.tex("res://art/ui/items.png")
	icon.region_enabled = true
	icon.region_rect = Rect2(int(item["icon"][1]) * ICON, int(item["icon"][0]) * ICON, ICON, ICON)
	icon.position = Vector2(0, -8)
	icon.scale = Vector2(0.75, 0.75)
	add_child(PropSprite.shadow(14.0))
	add_child(icon)
	var col: Color = GameData.rarity_color(item["rarity"])
	if item["rarity"] != "normal":
		var beam := PointLight2D.new()
		beam.texture = LightTex.soft(64)
		beam.texture_scale = BEAM_RANGE / 32.0
		beam.color = col
		beam.energy = BEAM_ENERGY
		add_child(beam)
		Fx.burst(Game.current.fx_layer, position, 10, Vector2(20, 60), 0.6, [col, Color(col, 0.0)], Vector2.UP, 25.0)
	label = Label.new()
	label.label_settings = UiDraw.label_settings(UiDraw.BODY, col)
	label.text = String(item["name"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(label_width(), LABEL_H)
	label.position = Vector2(-label_width() / 2.0, LABEL_Y)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Overlay.follower(self).add_child(label)
	var drop := create_tween()
	position.y -= 16
	drop.tween_property(self, "position:y", position.y + 16, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func label_width() -> float:
	return UiDraw.label_settings(UiDraw.BODY, Color.WHITE).font.get_string_size(String(item["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, UiDraw.BODY).x + 8.0


## The clickable name plate, in world coordinates.
func label_rect() -> Rect2:
	return Rect2(global_position + Vector2(-label_width() / 2.0, LABEL_Y - stack_lift), Vector2(label_width(), LABEL_H))


func _process(_delta: float) -> void:
	label.position.y = LABEL_Y - stack_lift
	label.visible = LabelStack.shown
