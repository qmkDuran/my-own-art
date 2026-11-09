class_name BrinelobShellGuard
extends HitShield
## A Brinelob's shell wall: hits from in front plink off it (no damage, no reaction) and push
## the attacker back a little. Hits from the back or sides get through, and so do sweeps that
## come round it (the Spinning Hook) and burn ticks (they never ask about deflecting).
## The guard drops for a moment after each claw snap (`drop_for`).
##
## It turns to face the player at a limited speed, so circling it works. Where it faces is
## drawn as a thin arc on the ground in front of it while the guard is up (the only cue a
## front-view sprite can give), and a plink shows a small ring where the hit bounced.

const ARC_COLOR := ApolloPalette.SKY
const ARC_ALPHA := 0.7
## Squash, so the arc lies flat on the ground.
const GROUND_SQUASH := 0.6

## Half the width of the guarded front, in degrees (hits within this of its facing bounce).
@export var front_half_angle: float = 55.0
## How fast it turns to face the player, in degrees per second.
@export var turn_speed: float = 140.0
## The push a bounced attacker gets: speed in pixels per second, and seconds.
@export var push_speed: float = 70.0
@export var push_time: float = 0.12
## The ring shown where a hit plinks off.
@export var plink_scene: PackedScene
@export var plink_radius: float = 4.0
@export var plink_time: float = 0.12
## Radius of the facing arc on the ground, in pixels.
@export var arc_radius: float = 15.0

## Which way the shell faces (unit vector).
var facing: Vector2 = Vector2.DOWN

var _seconds_dropped: float = 0.0

@onready var body: Node2D = get_parent()


func _physics_process(delta: float) -> void:
	_seconds_dropped = maxf(0.0, _seconds_dropped - delta)
	queue_redraw()


## True while the guard is up (hits from in front bounce).
func is_raised() -> bool:
	return _seconds_dropped <= 0.0


## Lowers the guard for `seconds` (e.g. right after a snap).
func drop_for(seconds: float) -> void:
	_seconds_dropped = seconds


## Turns toward `point` this frame, at most `turn_speed`.
func turn_toward(point: Vector2, delta: float) -> void:
	var wanted := body.global_position.direction_to(point)
	if wanted == Vector2.ZERO:
		return
	var turn := clampf(facing.angle_to(wanted), -deg_to_rad(turn_speed) * delta, deg_to_rad(turn_speed) * delta)
	facing = facing.rotated(turn)


## True when a hit from `source_position` comes at the guarded front.
func faces(source_position: Vector2) -> bool:
	var to_source := body.global_position.direction_to(source_position)
	return absf(rad_to_deg(facing.angle_to(to_source))) <= front_half_angle


func deflects(source_position: Vector2, kind: Health.HitKind) -> bool:
	if not is_raised() or kind == Health.HitKind.SWEEP or not faces(source_position):
		return false
	_plink(source_position)
	return true


func _plink(source_position: Vector2) -> void:
	var to_source := body.global_position.direction_to(source_position)
	if plink_scene != null:
		Shockwave.spawn(plink_scene, body.get_parent(), CreatureBody.middle_of(body) + to_source * arc_radius, plink_radius, plink_time, ApolloPalette.WHITE)
	var player := PlayerFinder.find(self)
	if player != null and player.global_position.distance_to(source_position) < 1.0:
		PlayerHit.shove(player, to_source * push_speed, push_time)


func _draw() -> void:
	if not is_raised():
		return
	var steps := ceili(arc_radius * deg_to_rad(front_half_angle) * 2.0)
	for step in steps + 1:
		var angle := facing.angle() + deg_to_rad(lerpf(-front_half_angle, front_half_angle, float(step) / steps))
		var at := Vector2(cos(angle) * arc_radius, sin(angle) * arc_radius * GROUND_SQUASH)
		draw_rect(Rect2(at.round(), Vector2.ONE), Color(ARC_COLOR, ARC_ALPHA))
