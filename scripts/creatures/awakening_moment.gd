class_name AwakeningMoment
extends Node
## The short awakening moment when Emberoo Awakens (Awakening's `awakened`): he stops and
## faces the camera, light gathers, then a flare (a ring of his new blue fire and
## shockwaves) and the new look sticks. The HUD's AwakeningAnnouncement flashes the screen
## and shows the banner at the same flare.
##
## While it plays the creature ignores its controls (it asks `is_playing`) and can't be hurt.

## Seconds from the start to the flare, when the new look appears.
const FLARE_DELAY := 0.45
## Seconds the whole moment lasts before control comes back.
const DURATION := 1.2
## Height of the body's middle above the feet, in pixels (negative is up).
const BODY_HEIGHT := Creature.BODY_HEIGHT

## While the light gathers: a small ring this wide, lasting this long.
@export var gather_ring_radius: float = 12.0
@export var gather_ring_seconds: float = 0.35
## The flare: a fire ring this wide and shockwaves out to these radii.
@export var fire_ring_radius: float = 20.0
@export var shockwave_radii: Array[float] = [22.0, 36.0, 52.0]
@export var shockwave_seconds: float = 0.55
@export var flare_shake_strength: float = 2.5
@export var flare_shake_seconds: float = 0.3

@export_group("Parts")
@export var look: AwakeningLook
@export var animator: CreatureAnimator
@export var facing: Facing
@export var health: Health
@export var hit_flash: HitFlash
@export var screen_shake: ScreenShake
## The expanding ring effect (Shockwave).
@export var ring_scene: PackedScene

## True from the start of the moment until control comes back.
var is_playing: bool = false

@onready var _creature: Creature = get_parent()


func _ready() -> void:
	Awakening.awakened.connect(play)


func play(stage: int) -> void:
	is_playing = true
	health.is_invulnerable = true
	_creature.interrupt()
	_creature.mouse_orders.stop_walking()
	_creature.velocity = Vector2.ZERO
	facing.look_toward(Vector2.DOWN)
	animator.lift(0.0)
	animator.replay_animation("idle", facing)
	_gather()
	# A tween on this node, so nothing fires if the level restarts mid-moment.
	var timeline := create_tween()
	timeline.tween_interval(FLARE_DELAY)
	timeline.tween_callback(_flare.bind(stage))
	timeline.tween_interval(DURATION - FLARE_DELAY)
	timeline.tween_callback(_finish)


func _finish() -> void:
	is_playing = false
	health.is_invulnerable = false


## Light gathers: a flash on the body and a tight ring of his new flame colour.
func _gather() -> void:
	hit_flash.flash(EmberooFlameColors.warm())
	_spawn_ring(gather_ring_radius, gather_ring_seconds, EmberooFlameColors.warm())


## The new look sticks with a burst of his new fire.
func _flare(stage: int) -> void:
	look.show_stage(stage)
	hit_flash.flash(ApolloPalette.WHITE)
	var ring := FireRing.new()
	_creature.get_parent().add_child(ring)
	ring.global_position = _body_centre().round()
	ring.play(fire_ring_radius)
	var ramp := EmberooFlameColors.fire_ramp()
	for index in shockwave_radii.size():
		_spawn_ring(shockwave_radii[index], shockwave_seconds, ramp[mini(index, ramp.size() - 1)])
	screen_shake.shake(flare_shake_strength, flare_shake_seconds)


func _spawn_ring(radius: float, seconds: float, color: Color) -> void:
	if ring_scene != null:
		Shockwave.spawn(ring_scene, _creature.get_parent(), _body_centre(), radius, seconds, color)


func _body_centre() -> Vector2:
	return _creature.global_position + Vector2(0, BODY_HEIGHT)
