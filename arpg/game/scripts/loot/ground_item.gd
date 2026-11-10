class_name GroundItem
extends Node2D
## A dropped item: its icon on the ground with a light pillar for better rarities, and a coloured name label.
## Picked up by walking over it, or by clicking the label (Michael walks to it).

const PICKUP_RADIUS: float = 22.0
const LABEL_W: float = 160.0

var item: Dictionary
var label: Label


static func spawn(parent: Node, at: Vector2, it: Dictionary) -> GroundItem:
	var g := GroundItem.new()
	g.item = it
	g.position = at
	parent.add_child(g)
	return g


func _ready() -> void:
	var icon := Sprite2D.new()
	icon.texture = load("res://art/items/icons.png") as Texture2D
	icon.region_enabled = true
	var c: Vector2i = item["icon"]
	icon.region_rect = Rect2(c.x * 32, c.y * 32, 32, 32)
	icon.position = Vector2(0, -12)
	add_child(icon)
	var col: Color = GameData.rarity_color(item["rarity"])
	if item["rarity"] != "common":
		var beam := PointLight2D.new()
		beam.texture = LightTex.radial(64)
		beam.color = col
		beam.energy = 0.9
		beam.position = Vector2(0, -12)
		add_child(beam)
	label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.font_color = col
	ls.outline_size = 4
	ls.outline_color = Color("2e222f")
	label.label_settings = ls
	label.text = item["name"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(LABEL_W, 16)
	label.position = Vector2(-LABEL_W / 2.0, -46)
	Overlay.follower(self).add_child(label)
	var drop := create_tween()
	position.y -= 18
	drop.tween_property(self, "position:y", position.y + 18, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func label_rect() -> Rect2:
	var w: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 8.0
	return Rect2(global_position + Vector2(-w / 2.0, -46), Vector2(w, 18))
