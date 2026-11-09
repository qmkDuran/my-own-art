class_name StompIntro
extends SignalSkill
## Mossdillo's Intro: it drops from the sky and lands in a stomp, with a shockwave and a
## burst of flying leaves. Signal Skill on Airborne (Launched) enemies, which it slams down,
## or Burning ones (Bloom on Burning sets off Wildfire); everything it hits is Rooted.

const DROP_HEIGHT := 90.0
const LEAVES: Array[Color] = [ApolloPalette.GREEN, ApolloPalette.GREEN_LIGHT, ApolloPalette.LIME_PALE, ApolloPalette.PINK]
const DIRT: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK]
const ROOT_SECONDS := 2.0
const SHOCKWAVE_RADIUS := 40.0


func _arrive(member: PlayableCreature, _targets: Array[Health]) -> void:
	SpriteMotion.slide(SpriteMotion.sprite_of(member), Vector2(0, -DROP_HEIGHT), Vector2.ZERO, arrival_seconds,
			Tween.TRANS_QUAD, Tween.EASE_IN)
	var lines := member.get_node_or_null("SpeedLines") as SpeedLines
	if lines != null:
		lines.play_for(arrival_seconds, Vector2.DOWN)


func _touch_down(member: PlayableCreature) -> void:
	var world := member.get_parent()
	var feet := member.global_position
	Shockwave.spawn(HitFeel.RING_SCENE, world, feet, SHOCKWAVE_RADIUS, 0.35, ApolloPalette.GREEN_LIGHT)
	Shockwave.spawn(HitFeel.RING_SCENE, world, feet, SHOCKWAVE_RADIUS * 0.65, 0.28, ApolloPalette.CORK)
	Shockwave.spawn(HitFeel.RING_SCENE, world, feet, SHOCKWAVE_RADIUS * 0.35, 0.2, ApolloPalette.WHITE)
	var leaves := PixelDebris.spray(world, feet + Vector2(0, -6), LEAVES, 26, Vector2.UP, 220.0)
	leaves.gravity = 70.0
	leaves.sway = 25.0
	leaves.lifetime = 1.0
	PixelDebris.spray(world, feet, DIRT, 18, Vector2.UP, 160.0)
	HitFeel.shake(member, 3.0, 0.22)
	var front_view := member as FrontViewCreature
	if front_view != null:
		front_view.play_pose("intro")


func _after_strike(_member: PlayableCreature, targets: Array[Health]) -> void:
	for target_health in targets:
		SetUp.consume(target_health.get_parent(), SetUp.LAUNCHED)
		SetUp.apply(target_health, SetUp.ROOTED, ROOT_SECONDS)
