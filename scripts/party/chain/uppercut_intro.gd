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

@export var knockback_speed: float = 120.0
@export var impact_scene: PackedScene


func guide_line() -> String:
	return "%d dmg to each set-up enemy within %d px, throws them up again (Airborne %.1f s)." % [damage, reach, RELAUNCH_SECONDS]


func _arrive(member: PlayableCreature, targets: Array[Health]) -> void:
	var toward_enemy := _side_toward(member, targets)
	var sprite := SpriteMotion.sprite_of(member)
	var start := Vector2(-toward_enemy * FLY_IN_FROM.x, FLY_IN_FROM.y)
	SpriteMotion.slide(sprite, start, Vector2.ZERO, arrival_seconds, Tween.TRANS_LINEAR)
	var lines := member.get_node_or_null("SpeedLines") as SpeedLines
	if lines != null:
		lines.play_for(arrival_seconds, -start)
	var trail := PixelDebris.spray(member.get_parent(), member.global_position + start * 0.5, EMBERS, 12, start, 50.0)
	trail.gravity = -40.0


func _touch_down(member: PlayableCreature) -> void:
	var world := member.get_parent()
	PixelDebris.spray(world, member.global_position, DUST, 14, Vector2.UP, 150.0)
	Shockwave.spawn(HitFeel.RING_SCENE, world, member.global_position, 16.0, 0.25, ApolloPalette.ORANGE)
	HitFeel.shake(member, 2.0, 0.15)


func _after_strike(member: PlayableCreature, targets: Array[Health]) -> void:
	AbilityTargets.knock_back_all(targets, member.global_position, knockback_speed)
	for target_health in targets:
		var enemy := target_health.get_parent() as Node2D
		var flame := FlameArc.new()
		member.get_parent().add_child(flame)
		flame.global_position = enemy.global_position + Vector2(0, 4)
		flame.play(Vector2.UP, 24.0, 120.0)
		if impact_scene != null:
			var impact := impact_scene.instantiate() as Node2D
			member.get_parent().add_child(impact)
			impact.global_position = enemy.global_position + Vector2(0, -10)
		SetUp.apply(target_health, SetUp.LAUNCHED, RELAUNCH_SECONDS)
	SpriteMotion.hop(SpriteMotion.sprite_of(member), UPPERCUT_HOP, 0.3)
	ScreenFlash.play(member, ApolloPalette.GOLD)


## +1 when the set-up enemies are to his right (he flies in from the left), else -1.
func _side_toward(member: PlayableCreature, targets: Array[Health]) -> float:
	if targets.is_empty():
		return 1.0
	var enemy := targets[0].get_parent() as Node2D
	return 1.0 if enemy.global_position.x >= member.global_position.x else -1.0
