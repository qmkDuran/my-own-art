class_name AmbushIntro
extends SignalSkill
## Ripfin's Intro: it surfaces behind the nearest enemy, erupting from the ground in a spray
## of dirt and water. Signal Skill on Rooted or Broken enemies: a bite that sets off a Drown
## (Tide on Rooted); on Soaked enemies the ambush always crits.

const BEHIND_DISTANCE := 12.0
## How close to the surfacing spot an enemy must be for the bite to reach it.
const BITE_RADIUS := 26.0
## The same dirt-and-water spray as its Riptide Ambush.
const SPRAY := RiptideAmbush.SPRAY
const SPRAY_PIXELS := 34
const ERUPT_HEIGHT := 12.0
const ERUPT_SECONDS := 0.32
const SUBMERGED_POSE := "submerged"
const SURFACED_POSE := "intro"
const DIVE_RING_RADIUS := 10.0
const ERUPT_SHAKE := 2.0
const ERUPT_SHAKE_SECONDS := 0.15


func guide_line() -> String:
	return "Surfaces behind the enemy: %d dmg bite within %d px. Always crits on Soaked." % [damage, BITE_RADIUS]


func _arrive(member: PlayableCreature, targets: Array[Health]) -> void:
	var prey := AbilityTargets.nearest_to(member.global_position, targets)
	if prey == null:
		prey = AbilityTargets.nearest_to(member.global_position, AbilityTargets.within(self, member.global_position, reach))
	if prey != null:
		var enemy := prey.get_parent() as Node2D
		var away := enemy.global_position - member.global_position
		away = away.normalized() if away.length() > 1.0 else Vector2.RIGHT
		member.global_position = (enemy.global_position + away * BEHIND_DISTANCE).round()
	var front_view := member as FrontViewCreature
	if front_view != null:
		front_view.play_pose(SUBMERGED_POSE)
	Shockwave.spawn(HitFeel.RING_SCENE, member.get_parent(), member.global_position, DIVE_RING_RADIUS, arrival_seconds, ApolloPalette.SKY_LIGHT)


func _touch_down(member: PlayableCreature) -> void:
	var front_view := member as FrontViewCreature
	if front_view != null:
		front_view.play_pose(SURFACED_POSE)
	SpriteMotion.hop(SpriteMotion.sprite_of(member), ERUPT_HEIGHT, ERUPT_SECONDS)
	var world := member.get_parent()
	var spray := PixelDebris.spray(world, member.global_position, SPRAY, SPRAY_PIXELS, Vector2.UP, 110.0)
	spray.speed_range = Vector2(60, 160)
	Shockwave.spawn(HitFeel.RING_SCENE, world, member.global_position, 20.0, 0.3, ApolloPalette.SKY)
	Shockwave.spawn(HitFeel.RING_SCENE, world, member.global_position, 12.0, 0.22, ApolloPalette.CORK)
	HitFeel.shake(member, ERUPT_SHAKE, ERUPT_SHAKE_SECONDS)


func _strike_targets(member: PlayableCreature) -> Array[Health]:
	var close: Array[Health] = []
	for target_health in _set_up_targets(member.global_position):
		if (target_health.get_parent() as Node2D).global_position.distance_to(member.global_position) <= BITE_RADIUS:
			close.append(target_health)
	return close


func _before_strike(member: PlayableCreature, targets: Array[Health]) -> void:
	var crit_roll := member.get_node_or_null(CritRoll.NODE_NAME) as CritRoll
	if crit_roll == null:
		return
	for target_health in targets:
		if SetUp.has(target_health.get_parent(), SetUp.SOAKED):
			crit_roll.is_sure_crit = true


func _after_strike(member: PlayableCreature, _targets: Array[Health]) -> void:
	var crit_roll := member.get_node_or_null(CritRoll.NODE_NAME) as CritRoll
	if crit_roll != null:
		crit_roll.is_sure_crit = false
