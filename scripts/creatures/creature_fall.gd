class_name CreatureFall
extends RefCounted
## The player creature falling (health at zero) and getting back up at a checkpoint.
## Respawner decides when; this knows what happens to the creature and its components.
##
## Falling: it freezes on its crouched hop frame, sags, darkens and fades away (tweens that
## ignore the time scale, so the death's slow motion doesn't drag them out).
## Getting up: full health, no Heat, every Trainer's Aid charge, no status effects, the
## fall's look undone, then it bounds in onto the checkpoint (ZoneEntrance).

## The pose held while collapsing (the dodge's crouch).
const COLLAPSE_ANIMATION := "hop"
## Share of the collapse spent darkening before it fades away.
const DARKEN_SHARE := 0.4
## How far the sprite sags by the end: its width and height scale.
const SAG_SCALE := Vector2(1.2, 0.6)


## Plays the collapse over `seconds` (real time).
static func collapse(creature: Creature, seconds: float) -> void:
	creature.velocity = Vector2.ZERO
	creature.interrupt()
	creature.mouse_orders.stop_walking()
	creature.animator.replay_animation(COLLAPSE_ANIMATION, creature.facing)
	creature.animator.pause()
	var fall := creature.create_tween().set_ignore_time_scale(true).set_trans(Tween.TRANS_SINE).set_parallel()
	fall.tween_property(creature, "modulate", Color(ApolloPalette.PLUM_DARK, 1.0), seconds * DARKEN_SHARE)
	fall.tween_property(creature.animator, "scale", SAG_SCALE, seconds)
	fall.tween_property(creature, "modulate:a", 0.0, seconds * (1.0 - DARKEN_SHARE)).set_delay(seconds * DARKEN_SHARE)


## Brings the creature back at `spawn_point`, fully restored.
static func get_up_at(creature: Creature, spawn_point: Vector2) -> void:
	StatusEffect.clear_from(creature)
	creature.health.revive()
	creature.skill_bar.heat.cool_down_fully()
	creature.trainer_aid.refill()
	creature.velocity = Vector2.ZERO
	creature.modulate = Color.WHITE
	creature.animator.scale = Vector2.ONE
	creature.animator.play()
	bound_in_at(creature, spawn_point)


## Moves the creature to `spawn_point` with the zone-entrance hop, the camera jumping along.
static func bound_in_at(creature: Creature, spawn_point: Vector2) -> void:
	creature.zone_entrance.play_at(spawn_point)
	var camera := creature.get_viewport().get_camera_2d()
	if camera != null:
		camera.reset_smoothing()
