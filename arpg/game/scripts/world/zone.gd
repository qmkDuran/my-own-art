class_name Zone
extends Node2D
## The ruined suburb at night (data: res://data/zone.json; art: Project R exterior, darkened and ruined by hand).
## Builds the ground, y-sorted props with footprints, the night tint, working and broken lights, fire and ash.

const PROP_DIR: String = "res://art/zone/"
const LAMP_COLOR := Color(1.0, 0.82, 0.55)
const FIRE_COLOR := Color(1.0, 0.5, 0.2)

var world: Node2D
var _flickers: Array[PointLight2D] = []
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
		var light := PointLight2D.new()
		light.texture = LightTex.radial(384)
		light.position = Vector2(float(l[0]), float(l[1]))
		light.energy = float(l[2])
		light.color = FIRE_COLOR if l[3] == "fire" else LAMP_COLOR
		add_child(light)
		if l[3] != "lamp":
			_flickers.append(light)
	for f: Array in z["fires"]:
		Fx.embers(self, SceneData.vec(f))
	var size: Vector2 = SceneData.vec(z["size"])
	Fx.ash(self, Rect2(Vector2(0, -40), size), 140)


func _process(delta: float) -> void:
	_t += delta
	for i: int in _flickers.size():
		var l: PointLight2D = _flickers[i]
		l.energy = 0.75 + 0.35 * sin(_t * (9.0 + i * 3.0)) * sin(_t * 2.3 + i) + (0.0 if randf() > 0.03 else -0.5)


## Which verse caption belongs where (first matching rect).
func caption_at(p: Vector2) -> String:
	for r: Array in GameData.zone["zones"]:
		if SceneData.rect(r).has_point(p):
			return r[4]
	return ""
