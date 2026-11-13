class_name Ward
extends Node3D
## The ward: a short-lived honey-gold honeycomb bubble around the Lamplighter, with a glowing ring at their feet,
## that stops enemy shots (they splash on it with a ripple and a chime). It doesn't stop ground attacks: step out
## of those. On a cooldown.

var active: bool = false
var _kit: LamplighterKit
var _bubble: Bubble
var _light: OmniLight3D
var _ring: MeshInstance3D
var _left: float = 0.0


func setup(kit: LamplighterKit) -> void:
	name = "Ward"
	_kit = kit
	position.y = Tuning.number("combat", "player", "chest_height")


func raise() -> bool:
	if active or _kit.busy() or not (_kit.cooldowns["ward"] as Cooldown).is_ready():
		return false
	active = true
	_left = Tuning.number("combat", "ward", "seconds")
	var spec: Dictionary = _kit.fx.look("ward")
	_bubble = Bubble.new()
	add_child(_bubble)
	_bubble.setup(spec, Tuning.number("combat", "ward", "radius"))
	_light = OmniLight3D.new()
	_light.light_color = Tuning.color(spec["color"])
	_light.light_energy = float(spec["light_energy"])
	_light.omni_range = float(spec["light_range"])
	add_child(_light)
	_ring = RingMesh.make(Tuning.color(spec["edge"]))
	var radius: float = Tuning.number("combat", "ward", "radius")
	_ring.scale = Vector3(radius, RingMesh.LIFT, radius)
	add_child(_ring)
	_ring.position.y = RingMesh.LIFT - position.y
	(_kit.cooldowns["ward"] as Cooldown).start()
	_kit.fx.kit.sfx.cue("ward_up", global_position)
	return true


## True when the ward is up and a point is inside it.
func blocks(point: Vector3) -> bool:
	return active and point.distance_to(global_position) <= Tuning.number("combat", "ward", "radius")


## A shot splashes on the ward.
func absorb(point: Vector3) -> void:
	_bubble.ripple(point)
	_kit.fx.kit.sfx.cue("ward_block", point)


func _process(delta: float) -> void:
	if not active:
		return
	_left -= delta
	var fade: float = Tuning.number("combat", "ward", "pulse_seconds")
	_bubble.set_strength(clampf(_left / fade, 0.0, 1.0))
	if _left <= 0.0:
		active = false
		_bubble.queue_free()
		_light.queue_free()
		_ring.queue_free()
