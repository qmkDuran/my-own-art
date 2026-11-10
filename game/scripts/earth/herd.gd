class_name Herd
extends Node2D
## The peaceable animals (Isa 11:6-7; 65:25): the wolf with the lamb, the leopard with the kid, the calf with
## the young lion, the lion eating straw with the ox, the cow and the bear feeding. Two-frame idles
## (breathing / grazing), and now and then a very quiet voice of the flock or herd when the player is near.

const ART: String = "res://art/earth/"
const GRAZERS: Array[String] = ["lion", "ox", "bear", "cow"]
const VOICES: Array[String] = ["lamb", "cow"]
const FOOT_FRAC: float = 0.64
const FOOT_DEPTH: float = 10.0
const HEAR: float = 220.0
const VOICE_MIN: float = 5.0
const VOICE_MAX: float = 9.0

var _animals: Array[Sprite2D] = []
var _next_voice: float = 4.0


## `world` gets the y-sorted animal sprites; this node holds their blockers.
func build(entries: Array, world: Node2D) -> void:
	for a: Array in entries:
		var s := SpriteFactory.grounded(world, ART + "an_%s.png" % a[0], Vector2(a[1], a[2]), 2)
		s.set_meta("kind", a[0])
		s.set_meta("phase", randf_range(0.0, 6.0))
		_animals.append(s)
		var w: float = s.texture.get_width() / 2.0
		Blockers.add(self, Rect2(float(a[1]) - w * FOOT_FRAC / 2.0, float(a[2]) - FOOT_DEPTH, w * FOOT_FRAC, FOOT_DEPTH))


func animate(time: float, delta: float, listener: Vector2) -> void:
	for a: Sprite2D in _animals:
		var eats: bool = String(a.get_meta("kind")) in GRAZERS
		var cycle: float = fmod(time + float(a.get_meta("phase")), 4.0 if eats else 5.0)
		a.frame = 1 if (eats and cycle < 2.2) or (not eats and cycle < 0.9) else 0
	_next_voice -= delta
	if _next_voice <= 0.0:
		_next_voice = randf_range(VOICE_MIN, VOICE_MAX)
		_voice(listener)


func _voice(listener: Vector2) -> void:
	for a: Sprite2D in _animals:
		var kind: String = a.get_meta("kind")
		if kind in VOICES and a.position.distance_to(listener) < HEAR:
			Audio.sfx(kind, -24.0, randf_range(0.95, 1.05))
			return
