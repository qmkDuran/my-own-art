class_name EntityFactory
extends RefCounted
## Turns a zone's "entities" entries into nodes. Every entry is composed from optional parts:
## art (sprite), solid (collision), interact (examine/talk/pickup/door), light, leaves (clothes).
## Kinds: prop (default), npc, enemy, light, trigger, spawn. See README "Zone data".

var _zone: Zone
var _auto_id := 0


func _init(zone: Zone) -> void:
	_zone = zone


func build(entry: Dictionary) -> void:
	var id := String(entry.get("id", ""))
	if id.is_empty():
		_auto_id += 1
		id = "%s_%d" % [_zone.zone_id, _auto_id]
	var kind := String(entry.get("kind", "prop"))
	if kind == "spawn":
		_zone.add_spawn(id, _position(entry))
		return
	var extra: Variant = null
	var node: Node2D
	match kind:
		"trigger":
			node = _trigger(entry, id)
			if entry.get("once", true):
				extra = "!done:" + id
		"enemy":
			node = _enemy(entry, id)
			if entry.has("defeat_flag"):
				extra = "!" + String(entry["defeat_flag"])
		"npc":
			node = _npc(entry, id)
		"light":
			node = Node2D.new()
			node.position = _position(entry)
			_add_light(node, entry.get("light", "porch"))
		_:
			node = _prop(entry, id)
	var interact: Dictionary = entry.get("interact", {})
	if String(interact.get("type", "")) == "pickup":
		extra = "!taken:" + id
	node.name = id.validate_node_name()
	_zone.add_entity(id, node, Condition.combine(entry.get("if"), extra), entry.get("floor", false))
	if entry.has("leaves"):
		_build_leftover(entry, id)


# --- Kinds -----------------------------------------------------------------------

func _prop(entry: Dictionary, id: String) -> Node2D:
	var node := Node2D.new()
	node.position = _position(entry)
	var flip: bool = entry.get("flip", false)
	if entry.has("art"):
		var sprite := _sprite(String(entry["art"]), String(entry.get("anchor", "bottom")))
		if flip:
			sprite.flip_h = true
		node.add_child(sprite)
	if entry.get("above", false):
		node.z_index = 20   # ceiling fixtures: drawn over everything in the room
	var solid: Variant = entry.get("solid")
	if solid is String and solid == "art":
		var art_id := String(entry.get("art", ""))
		var art := Art.entry(art_id)
		var rects: Array = [art.get("footprint")] + Array(art.get("solid_extra", []))
		for r: Variant in rects:
			if r is Array:
				_add_image_rect(node, art_id, r, flip)
	else:
		_add_solid(node, solid, entry.get("solid_offset"))
	for r: Variant in entry.get("solid_rects", []):
		_add_image_rect(node, String(entry.get("art", "")), r, flip)
	_add_interaction(node, entry, id, null)
	if entry.has("light"):
		_add_light(node, entry["light"])
	return node


func _npc(entry: Dictionary, id: String) -> Node2D:
	var node := Node2D.new()
	node.position = _position(entry)
	var visual := CharacterVisual.new()
	node.add_child(visual)
	visual.setup(String(entry.get("art", "")))
	visual.facing = _facing(String(entry.get("facing", "down")))
	_add_solid(node, entry.get("solid", [18, 10]), null)
	_add_interaction(node, entry, id, visual)
	return node


func _enemy(entry: Dictionary, id: String) -> Node2D:
	var enemy := Enemy.new()
	enemy.setup(String(entry.get("enemy", "looter")), id, String(entry.get("defeat_flag", "")), String(entry.get("on_defeat", "")))
	enemy.position = _position(entry)
	return enemy


func _trigger(entry: Dictionary, id: String) -> Node2D:
	var trigger := TriggerArea.new()
	var r: Array = entry.get("rect", [0, 0, 1, 1])
	var rect := Rect2(float(r[0]) * Tiles.SIZE, float(r[1]) * Tiles.SIZE, float(r[2]) * Tiles.SIZE, float(r[3]) * Tiles.SIZE)
	var done_flag := "done:" + id if entry.get("once", true) else ""
	trigger.setup(rect, String(entry.get("run", "")), done_flag)
	return trigger


## Clothes left behind when a character vanishes ("leaves": art id). Shown once "gone:<id>" is set.
func _build_leftover(entry: Dictionary, id: String) -> void:
	build({
		"id": id + "_clothes",
		"art": entry["leaves"],
		"pos": entry.get("pos"),
		"offset": [0, 6],
		"if": ZoneEntityLink.gone_flag(id),
		"interact": entry.get("leftover_interact", {"type": "examine", "text": "Just clothes. Still warm."}),
	})


# --- Parts -----------------------------------------------------------------------

## A solid rectangle given in the art's own pixel space ([x, y, w, h] from the image's top-left),
## for a bottom-centre anchored sprite. Used for buildings and other large footprints.
func _add_image_rect(node: Node2D, art_id: String, r: Array, flip: bool) -> void:
	var tex_size := Art.texture(art_id).get_size()
	var left := float(r[0]) - roundf(tex_size.x / 2.0)
	var w := float(r[2])
	if flip:
		left = -left - w
	var top := float(r[1]) - tex_size.y
	_add_solid(node, [w, float(r[3])], [left + w / 2.0, top + float(r[3])])


func _sprite(art_id: String, anchor: String) -> Sprite2D:
	var fx := Art.entry(art_id).get("fx", {}) as Dictionary
	if not fx.is_empty() and Art.has_real_texture(art_id):
		return FxSprite.create(art_id, fx)
	var sprite := Sprite2D.new()
	sprite.texture = Art.texture(art_id)
	var tex_size := sprite.texture.get_size()
	sprite.centered = anchor == "center"
	if anchor == "bottom":
		sprite.offset = Vector2(-roundf(tex_size.x / 2.0), -tex_size.y)
	return sprite


func _add_solid(node: Node2D, solid: Variant, offset: Variant) -> void:
	if not solid is Array:
		return
	var size := Tiles.vec2(solid)
	var body := StaticBody2D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var rect := RectangleShape2D.new()
	rect.size = size
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0) + Tiles.vec2(offset)
	body.add_child(shape)
	node.add_child(body)


func _add_interaction(node: Node2D, entry: Dictionary, id: String, visual: CharacterVisual) -> void:
	var data: Dictionary = entry.get("interact", {})
	if data.is_empty():
		return
	var interactable: Interactable
	match String(data.get("type", "examine")):
		"talk":
			var talk := TalkInteractable.new()
			talk.setup(data, visual)
			interactable = talk
		"pickup":
			var pickup := PickupInteractable.new()
			pickup.setup(data, id)
			interactable = pickup
		"door":
			var door := DoorInteractable.new()
			door.setup(data)
			interactable = door
		_:
			var examine := ExamineInteractable.new()
			examine.setup(data)
			interactable = examine
	interactable.position = Tiles.vec2(data.get("offset"), Vector2(0, -8))
	interactable.add_circle(float(data.get("radius", 18.0)))
	node.add_child(interactable)


func _add_light(node: Node2D, spec: Variant) -> void:
	var light := LightSource.new()
	var overrides: Dictionary = {}
	var type_id := "porch"
	if spec is String:
		type_id = spec
	elif spec is Dictionary:
		overrides = spec
		type_id = String(overrides.get("type", "porch"))
	light.setup(type_id, overrides)
	light.position = Tiles.vec2(overrides.get("offset"), Vector2.ZERO)
	node.add_child(light)
	_zone.register_light(light)
	if overrides.has("if"):
		_zone.link_condition(light, overrides["if"])


func _position(entry: Dictionary) -> Vector2:
	return Tiles.to_pixels(entry.get("pos", [0, 0])) + Tiles.vec2(entry.get("offset"))


static func _facing(direction: String) -> Vector2:
	match direction:
		"up":
			return Vector2.UP
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
	return Vector2.DOWN
