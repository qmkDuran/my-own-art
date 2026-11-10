class_name GroundItem
extends Node2D
## A dropped item: its icon on the ground with a light for better rarities, and a coloured name label.
## Picked up by clicking the label (Michael walks to it) — never by clicking the ground; an optional auto-pickup
## filter in settings takes items of chosen rarities when walked over. Labels stack (LabelStack); Alt toggles them.

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
	var ls := UiDraw.label_settings(UiDraw.BODY, col)
	label.label_settings = ls
	label.text = item["name"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(LABEL_W, 14)
	label.position = Vector2(-LABEL_W / 2.0, -46)
	Overlay.follower(self).add_child(label)
	add_to_group("ground_items")
	var drop := create_tween()
	position.y -= 18
	drop.tween_property(self, "position:y", position.y + 18, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


var stack_lift: float = 0.0             # set by LabelStack so labels never overlap


func label_rect() -> Rect2:
	var w: float = label.label_settings.font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiDraw.BODY).x + 8.0
	return Rect2(global_position + Vector2(-w / 2.0, -44 - stack_lift), Vector2(w, 14))


func _process(_delta: float) -> void:
	label.position.y = -44 - stack_lift
	label.visible = LabelStack.shown


## Should walking over this item take it? (settings "auto_pickup": "none", "all", or a rarity and better)
func auto_take() -> bool:
	var rule: String = String(GameData.settings.get("auto_pickup", "none"))
	if rule == "none":
		return false
	if rule == "all":
		return true
	var order: Array = ["common", "magic", "rare", "unique"]
	return order.find(item["rarity"]) >= order.find(rule)
