class_name ZoneEntrance
extends Node
## The short moment when a zone starts: the creature bounds in with one arcing hop,
## lands on its spawn point with a small ember burst and a ring of dust, holds a
## fighter's stance for a beat, and then play begins (under a second in all).
##
## While it plays, the creature ignores its controls (it asks `is_playing`) and can't be
## hurt. Any key, click or button press ends it early, so it never gets in the way.
## Turn `enabled` off where a level should start instantly (e.g. the test arena).

## The fire burst sheets are drawn pointing right; this turns one to point up.
const POINTING_UP := -PI / 2.0

@export var enabled: bool = true
## Where the hop starts, relative to the spawn point, in pixels (positive y is down the screen).
@export var entry_offset: Vector2 = Vector2(0, 20)
## How high above the ground the creature appears at the start, in pixels.
@export var start_height: float = 12.0
## How much higher the hop's arc rises on the way, in pixels.
@export var arc_height: float = 8.0
## Seconds in the air.
@export var hop_duration: float = 0.5
## Share of the hop spent fading in from invisible.
@export_range(0.0, 1.0) var fade_in_share: float = 0.3
## Seconds holding the fighter's stance after landing.
@export var stance_duration: float = 0.35
## Which way the creature looks once it lands (down = toward the camera).
@export var landing_look: Vector2 = Vector2.DOWN
## The action and frame posed as the fighter's stance (the jab's ready frame).
@export var stance_action: String = "jab"

@export_group("Landing effects")
## A burst of embers, played pointing up from the feet.
@export var ember_burst_scene: PackedScene
## A ring of dust spreading out along the ground.
@export var dust_ring_scene: PackedScene
@export var dust_ring_radius: float = 10.0
@export var dust_ring_duration: float = 0.3
@export var dust_ring_color: Color = Color(ApolloPalette.CREAM, 0.7)
@export var dust_puff_scene: PackedScene
## A tiny camera shake as the feet hit the ground, in pixels and seconds.
@export var shake_strength: float = 1.0
@export var shake_duration: float = 0.15

@export_group("Parts")
@export var animator: CreatureAnimator
@export var facing: Facing
@export var health: Health
@export var screen_shake: ScreenShake

## True from the start of the hop until play begins.
var is_playing: bool = false

var _creature: Node2D
var _spawn_point: Vector2
var _entry_point: Vector2
var _elapsed: float = 0.0
var _has_landed: bool = false


func _ready() -> void:
	_creature = get_parent() as Node2D
	if enabled:
		_begin()


func _physics_process(delta: float) -> void:
	if not is_playing:
		return
	_elapsed += delta
	if not _has_landed:
		_advance_hop()
	elif _elapsed >= hop_duration + stance_duration:
		_finish()


## Any key, click or button press skips straight to play.
func _input(event: InputEvent) -> void:
	if is_playing and _is_press(event):
		_finish()


func _begin() -> void:
	is_playing = true
	_elapsed = 0.0
	_has_landed = false
	_spawn_point = _creature.global_position
	_entry_point = _spawn_point + entry_offset
	health.is_invulnerable = true
	facing.look_toward(-entry_offset)
	animator.replay_animation("hop", facing)
	_advance_hop()


## Moves along the arc: from high up at the entry point, over a small rise, down onto the spawn point.
func _advance_hop() -> void:
	var progress := clampf(_elapsed / hop_duration, 0.0, 1.0)
	_creature.global_position = _entry_point.lerp(_spawn_point, progress).round()
	animator.lift(lerpf(start_height, 0.0, progress) + sin(PI * progress) * arc_height)
	_creature.modulate.a = clampf(progress / maxf(fade_in_share, 0.001), 0.0, 1.0)
	if progress >= 1.0:
		_land()


func _land() -> void:
	_has_landed = true
	_creature.global_position = _spawn_point
	animator.lift(0.0)
	_creature.modulate.a = 1.0
	_play_landing_effects()
	_strike_stance()


## Holds the stance action's first frame (fists up, ready to jab).
func _strike_stance() -> void:
	facing.look_toward(landing_look)
	animator.replay_animation(stance_action, facing)
	animator.pause()


func _play_landing_effects() -> void:
	var world := _creature.get_parent()
	if ember_burst_scene != null:
		var burst: Node2D = ember_burst_scene.instantiate()
		world.add_child(burst)
		burst.global_position = _spawn_point
		burst.rotation = POINTING_UP
	if dust_ring_scene != null:
		Shockwave.spawn(dust_ring_scene, world, _spawn_point, dust_ring_radius, dust_ring_duration, dust_ring_color)
	DustPuff.spawn(dust_puff_scene, world, _spawn_point)
	screen_shake.shake(shake_strength, shake_duration)


## Hands control back: on the spawn point, on the ground, fully visible and hurtable again.
func _finish() -> void:
	is_playing = false
	_creature.global_position = _spawn_point
	_creature.modulate.a = 1.0
	animator.lift(0.0)
	facing.look_toward(landing_look)
	animator.play()
	health.is_invulnerable = false


func _is_press(event: InputEvent) -> bool:
	var is_button := event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton
	return is_button and event.is_pressed() and not event.is_echo()
