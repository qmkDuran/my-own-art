class_name SunMote
extends Node3D
## One fiery mote rained by the Sunrise: a flame wisp falling from the sun to a point on the ground, where it
## bursts and hurts every enemy within mote_radius.

var _kit: LamplighterKit
var _target: Vector3 = Vector3.ZERO
var _wisp: FlameWisp
var _loud: bool = false


func launch(kit: LamplighterKit, from: Vector3, target: Vector3, loud: bool) -> void:
	name = "SunMote"
	_kit = kit
	_target = target
	_loud = loud
	kit.roster.add_effect(self, from)
	_wisp = FlameWisp.new()
	add_child(_wisp)
	_wisp.setup(kit.fx.kit, kit.fx.look("sun")["mote"], from.direction_to(target))


func _physics_process(delta: float) -> void:
	var step: float = Tuning.number("combat", "super", "mote_speed") * delta
	if global_position.distance_to(_target) <= step:
		_land()
		return
	global_position = global_position.move_toward(_target, step)


func _land() -> void:
	var spec: Dictionary = _kit.fx.look("sun")
	for enemy: Enemy in _kit.roster.within(_target, Tuning.number("combat", "super", "mote_radius")):
		enemy.take_hit(Hit.new(Tuning.number("combat", "super", "mote_damage"), "super", enemy.centre()))
	_kit.fx.impact_with(spec["mote_impact"], spec["mote_mark"], _target, _target)
	if _loud:
		_kit.fx.kit.sfx.cue("super_mote", _target)
	_wisp.leave_behind()
	queue_free()
