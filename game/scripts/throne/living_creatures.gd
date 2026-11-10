class_name LivingCreatures
extends Node2D
## The four living creatures (Rev 4:6-8): like a lion, a calf, with a face as a man, like a flying eagle;
## six wings each, full of eyes (jewel motifs). Slow, majestic wing beats with a very quiet rush of wings.

const ART: String = "res://art/throne/"
const WING_FRAMES: int = 6
const DOWNSTROKE: int = 3
const FOOT := Vector2(68, 18)
const AURA_SCALE := Vector2(0.2, 0.3)
const HEAR: float = 320.0

var creatures: Array[Sprite2D] = []
var _base: Array[Vector2] = []


## `world` gets the y-sorted sprites; this node holds blockers, sparkles and auras.
func build(entries: Array, world: Node2D) -> void:
	for c: Array in entries:
		var tex: Texture2D = load(ART + "creature_%s_flap.png" % c[0])
		var s := Sprite2D.new()
		s.texture = tex
		s.hframes = WING_FRAMES
		s.centered = false
		var frame_w: int = tex.get_width() / WING_FRAMES
		var bottom: int = SpriteFactory.content_bottom(tex, frame_w)
		s.offset = Vector2(-frame_w / 2.0, -bottom)
		s.position = Vector2(c[1], c[2])
		s.set_meta("kind", c[0])
		world.add_child(s)
		creatures.append(s)
		_base.append(s.position)
		Blockers.footprint(self, s.position, FOOT, 2.0)
		Fx.sparkles(self, s.position + Vector2(0, -bottom / 2.0), Vector2(46, bottom / 2.5), 10)
		SpriteFactory.glow(self, ART + "throne_glow.png", s.position + Vector2(0, -bottom * 0.55), AURA_SCALE, -11)


func animate(time: float, listener: Vector2) -> void:
	for i: int in creatures.size():
		var cr: Sprite2D = creatures[i]
		cr.position.y = _base[i].y - roundf(1.0 + sin(time * 1.2 + i * 1.6))
		var wf: int = int(time * 2.2 + i * 1.7) % WING_FRAMES   # one beat every ~2.7 s
		if wf != cr.frame and wf == DOWNSTROKE:
			var dist: float = listener.distance_to(cr.position)
			Audio.sfx("wing_whoosh", lerpf(-28.0, -42.0, clampf(dist / HEAR, 0.0, 1.0)), randf_range(0.9, 1.05))
		cr.frame = wf


## The kind of creature within `reach` of a position, or "".
func near(pos: Vector2, reach: float) -> String:
	for c: Sprite2D in creatures:
		if pos.distance_to(c.position) < reach:
			return c.get_meta("kind")
	return ""
