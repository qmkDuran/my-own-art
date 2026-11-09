class_name UppercutIntro
extends SignalSkill
## Emberoo's Intro: he flies in from the side in a streak of fire and lands a flaming
## uppercut. Signal Skill on Airborne (Launched) or Broken enemies: a big uppercut that
## throws them up again; on Soaked enemies the fire sets off a Steam Burst (a reaction).

const FLY_IN_FROM := Vector2(46, -22)
const DUST: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK, ApolloPalette.GOLD]
const EMBERS: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.RED_LIGHT]
const RELAUNCH_SECONDS := 1.4
const UPPERCUT_HOP := 10.0
const UPPERCUT_HOP_SECONDS := 0.3
const TRAIL_PIXELS := 12
const LANDING_DUST_PIXELS := 14
const LANDING_RING_RADIUS := 16.0
const LANDING_SHAKE := 2.0
const LANDING_SHAKE_SECONDS := 0.15
## Where on a struck enemy the flame rises from and the impact shows, from its feet.
const FLAME_OFFSET := Vector2(0, 4)
const IMPACT_OFFSET := Vector2(0, -10)

@export var knockback_speed: float = 120.0
@export var impact_scene: PackedScene


func guide_line() -> String:
	return "%d dmg to each set-up enemy within %d px, throws them up again (Airborne %.1f s)." % [damage, reach, RELAUNCH_SECONDS]


func _arrive(member: PlayableCreature, targets: Array[Health]) -> void:
	var toward_enemy := _side_toward(member, targets)
	var sprite := SpriteMotion.sprite_of(member)
	var fly_from := Vector2(-toward_enemy * FLY_IN_FROM.x, FLY_IN_FROM.y)
	SpriteMotion.slide(sprite, fly_from, Vector2.ZERO, arrival_seconds, Tween.TRANS_LINEAR)
	SpeedLines.play_on(member, arrival_seconds, -fly_from)
	var trail := PixelDebris.spray(member.get_parent(), member.global_position + fly_from * 0.5, EMBERS, TRAIL_PIXELS, fly_from, 50.0)
	trail.gravity = -40.0


func _touch_down(member: PlayableCreature) -> void:
	var world := member.get_parent()
	PixelDebris.spray(world, member.global_position, DUST, LANDING_DUST_PIXELS, Vector2.UP, 150.0)
	Shockwave.spawn(HitFeel.RING_SCENE, world, member.global_position, LANDING_RING_RADIUS, 0.25, ApolloPalette.ORANGE)
	HitFeel.shake(member, LANDING_SHAKE, LANDING_SHAKE_SECONDS)


func _after_strike(member: PlayableCreature, targets: Array[Health]) -> void:
	AbilityTargets.knock_back_all(targets, member.global_position, knockback_speed)
	for target_health in targets:
		var enemy := target_health.get_parent() as Node2D
		var flame := FlameArc.new()
		member.get_parent().add_child(flame)
		flame.global_position = enemy.global_position + FLAME_OFFSET
		flame.play(Vector2.UP, 24.0, 120.0)
		if impact_scene != null:
			var impact := impact_scene.instantiate() as Node2D
			member.get_parent().add_child(impact)
			impact.global_position = enemy.global_position + IMPACT_OFFSET
		SetUp.apply(target_health, SetUp.LAUNCHED, RELAUNCH_SECONDS)
	SpriteMotion.hop(SpriteMotion.sprite_of(member), UPPERCUT_HOP, UPPERCUT_HOP_SECONDS)
	ScreenFlash.play(member, ApolloPalette.GOLD)


## +1 when the set-up enemies are to his right (he flies in from the left), else -1.
func _side_toward(member: PlayableCreature, targets: Array[Health]) -> float:
	if targets.is_empty():
		return 1.0
	var enemy := targets[0].get_parent() as Node2D
	return 1.0 if enemy.global_position.x >= member.global_position.x else -1.0
