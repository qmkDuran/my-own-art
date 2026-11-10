class_name Zone
extends Node2D
## The zone at night (data: res://data/zone.json, written by art/build_zone.py): suburb, highway, park and rift.
## Builds the ground, y-sorted props with footprints, the night tint, the few lights (fires, a flickering lamp, the
## rift's red glow), the overpass overhead, embers, ash and the smoke rising from the Abyss (Rev 9:2).

const PROP_DIR: String = "res://art/zone/"
const LAMP_COLOR := Color(1.0, 0.82, 0.55)
const FIRE_COLOR := Color(1.0, 0.5, 0.2)
const RIFT_COLOR := Color(0.85, 0.15, 0.1)
const OVERHEAD_SEE_THROUGH: float = 0.45

var world: Node2D
var _flickers: Array[PointLight2D] = []
var _overhead: Array[Sprite2D] = []
var _t: float = 0.0


func build(into_world: Node2D) -> void:
	world = into_world
	var z: Dictionary = GameData.zone
	SpriteFactory.sprite(self, PROP_DIR + "ground.png", Vector2.ZERO, -20)
	var night := CanvasModulate.new()
	night.color = SceneData.color(z["night"])
	add_child(night)
	for p: Array in z["props"]:
		var feet := Vector2(float(p[1]), float(p[2]))
		SpriteFactory.grounded(world, PROP_DIR + "%s.png" % p[0], feet)
		Blockers.footprint(self, feet, Vector2(float(p[3]), float(p[4])))
	Blockers.add_all(self, z["colliders"])
	for l: Array in z["lights"]:
		if float(l[2]) <= 0.0:
			continue                                        # a broken streetlight
		var light := PointLight2D.new()
		light.texture = LightTex.radial(512 if l[3] == "rift" else 384)
		light.position = Vector2(float(l[0]), float(l[1]))
		light.energy = float(l[2])
		light.color = {"fire": FIRE_COLOR, "rift": RIFT_COLOR}.get(l[3], LAMP_COLOR)
		if l[3] == "rift":
			light.texture_scale = 2.0
		add_child(light)
		if l[3] != "lamp":
			_flickers.append(light)
	for f: Array in z["fires"]:
		Fx.embers(self, SceneData.vec(f))
	for o: Array in z["overhead"]:                          # the overpass: above everything, see-through when under it
		var s := SpriteFactory.sprite(self, PROP_DIR + "%s.png" % o[0], Vector2(float(o[1]), float(o[2])), 15)
		_overhead.append(s)
	var rift: Array = z["rift"]
	Fx.abyss_smoke(self, Vector2(float(rift[0]), float(rift[1])), Vector2(float(rift[2]) * 0.6, float(rift[3]) * 0.5))
	var size: Vector2 = SceneData.vec(z["size"])
	Fx.ash(self, Rect2(Vector2(0, -40), size), 140)


func _process(delta: float) -> void:
	_t += delta
	var m: Node2D = get_tree().get_first_node_in_group("michael")
	for s: Sprite2D in _overhead:
		var under: bool = m != null and Rect2(s.position, s.texture.get_size()).has_point(m.global_position)
		s.modulate.a = move_toward(s.modulate.a, OVERHEAD_SEE_THROUGH if under else 1.0, delta * 3.0)
	for i: int in _flickers.size():
		var l: PointLight2D = _flickers[i]
		l.energy = 0.75 + 0.35 * sin(_t * (9.0 + i * 3.0)) * sin(_t * 2.3 + i) + (0.0 if randf() > 0.03 else -0.5)


## Which verse caption belongs where (first matching rect).
func caption_at(p: Vector2) -> String:
	for r: Array in GameData.zone["zones"]:
		if SceneData.rect(r).has_point(p):
			return r[4]
	return ""
