class_name BombShell
extends Node3D
## A thrown lantern bomb: a spinning teal spirit-flame lantern following its arc exactly, trailing sparks; where the
## arc ends it bursts, hurting (and knocking back) every enemy within its radius.

const SHAKE: float = 4.0

var arc: BombArc
var _kit: LamplighterKit
var _time: float = 0.0
var _wisp: FlameWisp


func launch(kit: LamplighterKit, flight: BombArc) -> void:
	name = "BombShell"
	_kit = kit
	arc = flight
	kit.roster.add_effect(self, arc.from)
	var spec: Dictionary = kit.fx.look("bomb")
	var look: Dictionary = kit.fx.look("primary")["wisp"].duplicate()
	look["color"] = spec["color"]
	look["core_size"] = spec["shell_size"]
	look["energy"] = spec["shell_energy"]
	_wisp = FlameWisp.new()
	add_child(_wisp)
	_wisp.setup(kit.fx.kit, look, arc.velocity.normalized())


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= arc.landing_time:
		global_position = arc.landing
		_burst()
		return
	var next: Vector3 = arc.point_at(_time)
	if next.distance_squared_to(global_position) > Hit.TINY:
		_wisp.basis = Basis.looking_at(global_position.direction_to(next), Vector3.UP)
	global_position = next


func _burst() -> void:
	var radius: float = Tuning.number("combat", "bomb", "radius")
	for enemy: Enemy in _kit.roster.within(arc.landing, radius):
		var away: Vector3 = Vector3(enemy.global_position.x - arc.landing.x, 0.0, enemy.global_position.z -
			arc.landing.z).normalized()
		enemy.take_hit(Hit.new(Tuning.number("combat", "bomb", "damage"), "bomb", enemy.centre(), away *
			Tuning.number("combat", "bomb", "knockback")))
	BombBurstFx.new().play(_kit.fx, arc.landing, radius)
	_kit.fx.kit.sfx.cue("bomb_burst", arc.landing)
	_kit.fx.kit.hit_feel.nudge(Tuning.number("combat", "camera", "kick") * SHAKE, Tuning.number("combat", "bomb",
		"flight_min"))
	_wisp.leave_behind()
	queue_free()
