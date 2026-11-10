class_name ElderCircle
extends Node2D
## Twenty-four elders on thrones, in white with golden crowns, harps and golden bowls of incense (Rev 4:4; 5:8).
## In worship they cast their crowns before the throne and bow, then are crowned again (Rev 4:10-11).

const ART: String = "res://art/throne/"
const FRAME: float = 64.0
const FEET_Y: float = 62.0
const FRAMES: int = 4                       # sitting, bowing, bareheaded, bareheaded bowing
const SIT: int = 0
const BARE: int = 2
const BARE_BOW: int = 3
const BOWL_SIDE: float = 28.0
const BOWL_OFFSET := Vector2(-5, -13)       # a golden bowl on its own small stand, standing on the glass
const FOOT := Vector2(36, 12)
const CROWN_Z_FLYING: int = 4
const CROWN_Z_LYING: int = -1               # on the glass: anyone standing in front is drawn over it
const STAGGER: float = 0.04
const FLIGHT: float = 1.4
const BOW_TIME: float = 3.0
const ARC_HEIGHT: float = 40.0
const SLOTS_PER_ROW: int = 12
const CAPTION_TIME: float = 7.6

var elders: Array[Sprite2D] = []
var _crowns: Array[Sprite2D] = []
var _home: Array[Vector2] = []
var _slot: Array[Vector2] = []


## `world` gets the y-sorted elders and bowls; this node holds crowns, smoke and blockers.
func build(entries: Array, slots: Array, world: Node2D) -> void:
	var crown_pos: PackedStringArray = FileAccess.get_file_as_string(ART + "crown_pos.txt").split("\n")
	for e: Dictionary in entries:
		_add_elder(e, crown_pos[int(e["variant"])].split(","), world)
	_assign_slots(slots)


func _add_elder(e: Dictionary, cp: PackedStringArray, world: Node2D) -> void:
	var v: int = int(e["variant"])
	var face: int = int(e["face"])
	var pos := Vector2(e["x"], e["y"])
	var el := Sprite2D.new()
	el.texture = load(ART + "elder%d.png" % v)
	el.hframes = FRAMES
	el.centered = false
	el.flip_h = face < 0
	el.offset = Vector2(-FRAME / 2.0, -FEET_Y)
	el.position = pos
	world.add_child(el)
	elders.append(el)
	var crown_tex: Texture2D = load(ART + "crown%d.png" % v)
	var cx: float = float(cp[0]) if face > 0 else FRAME - float(cp[0]) - crown_tex.get_width()
	var home := pos + Vector2(cx - FRAME / 2.0, float(cp[1]) - FEET_Y)
	var crown := SpriteFactory.sprite(self, ART + "crown%d.png" % v, home, CROWN_Z_FLYING)
	crown.flip_h = face < 0
	crown.visible = false
	_crowns.append(crown)
	_home.append(home)
	var bowl := SpriteFactory.sprite(world, ART + "bowl.png", pos + Vector2(face * BOWL_SIDE, 0))
	bowl.offset = BOWL_OFFSET
	Fx.smoke(self, pos + Vector2(face * BOWL_SIDE, -13))
	Blockers.footprint(self, pos, FOOT, 2.0)


## Each crown has a place on the glass before the lamps; the order follows the elders from left to right.
func _assign_slots(slots: Array) -> void:
	var order: Array = range(elders.size())
	order.sort_custom(func(a: int, b: int) -> bool: return elders[a].position.x < elders[b].position.x)
	_slot.resize(elders.size())
	for rank: int in order.size():
		var slot: Array = slots[(rank % 2) * SLOTS_PER_ROW + rank / 2]
		var tex: Texture2D = _crowns[order[rank]].texture
		_slot[order[rank]] = Vector2(slot[0], slot[1]) - Vector2(tex.get_width() / 2.0, tex.get_height())


## Returns how long the worship takes (for the caption).
func worship(rng: RandomNumberGenerator) -> float:
	Audio.sfx("crown_cast", -12.0)
	get_tree().create_timer(5.8).timeout.connect(func() -> void: Audio.sfx("crown_cast", -16.0, 1.12))
	for i: int in elders.size():
		_cast_and_return(i, rng)
	return CAPTION_TIME


func _cast_and_return(i: int, rng: RandomNumberGenerator) -> void:
	var el: Sprite2D = elders[i]
	var crown: Sprite2D = _crowns[i]
	var tw := create_tween()
	tw.tween_interval(STAGGER * i)
	tw.tween_callback(func() -> void:
		el.frame = BARE
		crown.position = _home[i]
		crown.z_index = CROWN_Z_FLYING
		crown.visible = true)
	tw.tween_method(_fly.bind(crown, _home[i], _slot[i]), 0.0, 1.0, FLIGHT)
	tw.tween_callback(func() -> void:
		el.frame = BARE_BOW
		if i % 4 == 0:
			Audio.sfx("crown_land", -17.0, rng.randf_range(0.9, 1.15))
		crown.z_index = CROWN_Z_LYING)
	tw.tween_interval(BOW_TIME)
	tw.tween_callback(func() -> void:
		el.frame = BARE
		crown.z_index = CROWN_Z_FLYING)
	tw.tween_method(_fly.bind(crown, _slot[i], _home[i]), 0.0, 1.0, FLIGHT)
	tw.tween_callback(func() -> void:
		crown.visible = false
		el.frame = SIT)


## Smooth arc between head and floor, snapped to whole pixels.
func _fly(t: float, crown: Sprite2D, from: Vector2, to: Vector2) -> void:
	var e: float = t * t * (3.0 - 2.0 * t)
	crown.position = (from.lerp(to, e) - Vector2(0, sin(PI * t) * ARC_HEIGHT)).round()
