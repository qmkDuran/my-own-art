class_name Zone
extends Node2D
## One playable space built entirely from data/zones/<id>.json: ground tiles, y-sorted entities,
## lights, the ambient colour (CanvasModulate), music and ambience. Entities show and hide
## themselves as story flags change.

var zone_id := ""
var data: Dictionary = {}
var entities_root: Node2D

var _ground: GroundBuilder
var _ambient: CanvasModulate
var _ambient_tween: Tween
var _links: Array[ZoneEntityLink] = []
var _by_id: Dictionary = {}
var _spawns: Dictionary = {}
var _lights: Array[LightSource] = []


func build(id: String) -> void:
	zone_id = id
	name = "Zone_" + id
	data = DB.zone(id)
	_ground = GroundBuilder.new()
	var ground := _ground.build(data.get("map", []), data.get("legend", {}))
	ground.z_index = -10   # below floor decals (rugs, mats, spills: z -1) and everything else
	add_child(ground)
	add_child(_make_bounds())
	entities_root = Node2D.new()
	entities_root.name = "Entities"
	entities_root.y_sort_enabled = true
	add_child(entities_root)
	var factory := EntityFactory.new(self)
	for entry: Variant in data.get("entities", []):
		factory.build(entry)
	_ambient = CanvasModulate.new()
	_ambient.color = Color.from_string(String(setting("ambient", "#ffffff")), Color.WHITE)
	add_child(_ambient)
	refresh()
	Events.flag_changed.connect(_on_flag_changed)
	GameState.inventory.changed.connect(refresh)


## A zone setting, taken from the first matching "variants" entry, else the zone itself.
## Variants let one map serve several story moments (e.g. the street before/after the vanishing).
func setting(key: String, fallback: Variant = null) -> Variant:
	for variant: Variant in data.get("variants", []):
		var v: Dictionary = variant
		if v.has(key) and Condition.check(v.get("if")):
			return v[key]
	return data.get(key, fallback)


func start_audio() -> void:
	var music := String(setting("music", ""))
	if music.is_empty():
		AudioManager.stop_music()
	else:
		AudioManager.play_music(music)
	AudioManager.set_ambience(setting("ambience", []))


func entry_scripts() -> Array:
	return data.get("on_enter", [])


# --- Registration (used by EntityFactory) ------------------------------------------

func add_entity(id: String, node: Node2D, condition: Variant, on_floor: bool) -> void:
	if on_floor:
		node.z_index = -1
	entities_root.add_child(node)
	var link := ZoneEntityLink.new()
	link.entity_id = id
	link.condition = condition
	node.add_child(link)
	_links.append(link)
	_by_id[id] = node


## Makes any node (e.g. one light of a prop) follow a condition without giving it an id.
func link_condition(node: Node, condition: Variant) -> void:
	var link := ZoneEntityLink.new()
	link.condition = condition
	node.add_child(link)
	_links.append(link)


func add_spawn(id: String, pixel_position: Vector2) -> void:
	_spawns[id] = pixel_position


func register_light(light: LightSource) -> void:
	_lights.append(light)


# --- Queries -----------------------------------------------------------------------

func spawn_position(id: String) -> Vector2:
	if _spawns.has(id):
		return _spawns[id]
	if not _spawns.is_empty():
		return _spawns.values()[0]
	return bounds().get_center()


func entity(id: String) -> Node2D:
	return _by_id.get(id)


func is_entity_active(id: String) -> bool:
	var node := entity(id)
	return node != null and node.process_mode != Node.PROCESS_MODE_DISABLED


func bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(_ground.size * Tiles.SIZE))


## Footstep surface under a point ("wood", "carpet", "asphalt", "grass", ...).
func surface_at(point: Vector2) -> String:
	var tile_id := _ground.tile_at(Vector2i((point / Tiles.SIZE).floor()))
	return String((DB.tiles.get(tile_id, {}) as Dictionary).get("surface", "wood"))


func enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node: Variant in _by_id.values():
		if node is Enemy and (node as Enemy).process_mode != Node.PROCESS_MODE_DISABLED:
			result.append(node)
	return result


# --- Story effects -------------------------------------------------------------------

func refresh() -> void:
	for link: ZoneEntityLink in _links:
		link.apply()


func set_ambient(color: Color, duration: float) -> void:
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient, "color", color, maxf(duration, 0.01))


func ambient_color() -> Color:
	return _ambient.color


func set_light_group(group: String, state: String, duration: float) -> void:
	for light: LightSource in _lights:
		if light.group == group:
			light.set_state(state, duration)


## The character is simply not there any more (no flash, per the script); their clothes
## ("leaves" in the zone data) remain where they stood.
func vanish_entity(id: String) -> void:
	if entity(id) == null:
		push_error("vanish: no entity '%s' in zone '%s'" % [id, zone_id])
		return
	GameState.flags.set_flag(ZoneEntityLink.gone_flag(id))
	AudioManager.play_sfx("cloth_drop")


## Invisible walls around the map so nobody walks off the edge.
func _make_bounds() -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = "Bounds"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var area := bounds()
	var thickness := 64.0
	for rect: Rect2 in [
		Rect2(area.position.x - thickness, area.position.y - thickness, area.size.x + thickness * 2.0, thickness),
		Rect2(area.position.x - thickness, area.end.y, area.size.x + thickness * 2.0, thickness),
		Rect2(area.position.x - thickness, area.position.y, thickness, area.size.y),
		Rect2(area.end.x, area.position.y, thickness, area.size.y),
	]:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = rect.get_center()
		body.add_child(collider)
	return body


func _on_flag_changed(_flag: String, _value: Variant) -> void:
	refresh()
