class_name Interactable
extends Node2D
## Something Michael walks up to and uses with a click: a supply crate or lockbox (opens and drops gifts), or a
## waystone (found when passed; used to travel between found stones). Labelled on the unlit overlay.

signal used(it: Interactable)

const REACH: float = 46.0
const CHEST_ITEMS: Vector2i = Vector2i(2, 3)
const CHEST_QUALITY: float = 2.2
const NAMES: Dictionary = {"crate": "Supply Crate", "lockbox": "Lockbox"}

var kind: String                     # "crate", "lockbox", "waystone"
var title: String
var opened: bool = false             # chests: opened; waystones: found
var _sprite: Sprite2D
var _label: Label


static func make(parent: Node, k: String, name_text: String, at: Vector2) -> Interactable:
	var it := Interactable.new()
	it.kind = k
	it.title = name_text
	it.position = at
	parent.add_child(it)
	return it


func _ready() -> void:
	add_to_group("interactables")
	_sprite = SpriteFactory.grounded(self, "res://art/zone/%s.png" % ("waystone" if kind == "waystone" else kind), Vector2.ZERO)
	_sprite.light_mask = 1 | Demon.CHARACTER_LIGHT_MASK
	Blockers.footprint(self, Vector2.ZERO, Vector2(24, 10))
	_label = Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.font_color = Color("c7dcd0") if kind != "waystone" else Color("8fd3ff")
	ls.outline_size = 4
	ls.outline_color = Color("2e222f")
	_label.label_settings = ls
	_label.text = title
	_label.size = Vector2(140, 16)
	_label.position = Vector2(-70, -64 if kind == "waystone" else -42)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Overlay.follower(self).add_child(_label)


func click_rect() -> Rect2:
	return Rect2(global_position + Vector2(-28, -52 if kind == "waystone" else -34), Vector2(56, 56 if kind == "waystone" else 38))


func is_chest() -> bool:
	return kind != "waystone"


## Waystones are found by passing near them.
func notice_michael(m: Node2D) -> bool:
	if kind == "waystone" and not opened and m.global_position.distance_to(global_position) < REACH * 1.6:
		notice_michael_force()
		Audio.sfx("prayer", -12.0, 1.5)
		return true
	return false


func notice_michael_force() -> void:
	if not opened:
		opened = true
		_sprite.texture = load("res://art/zone/waystone_lit.png") as Texture2D
		var l := PointLight2D.new()
		l.texture = LightTex.radial(128)
		l.color = Color(1.0, 0.95, 0.65)
		l.energy = 0.7
		l.position = Vector2(0, -24)
		add_child(l)


func mark_opened() -> void:
	opened = true
	_sprite.texture = load("res://art/zone/%s_open.png" % kind) as Texture2D
	_label.modulate.a = 0.4


func use(world: Node2D, ilvl: int) -> void:
	if is_chest():
		if opened:
			return
		mark_opened()
		var items: Array = []
		for i: int in randi_range(CHEST_ITEMS.x, CHEST_ITEMS.y):
			items.append(LootGen.make(ilvl, CHEST_QUALITY, "magic" if i == 0 else ""))
		LootDrop.drop(world, global_position + Vector2(0, 14), items)
		Audio.sfx("crunch", -6.0)
		Audio.sfx("pickup", -10.0, 0.8)
	used.emit(self)
