class_name UpdraftOutro
extends SwapMove
## Zephoot's Outro: as it leaves, a column of wind throws every enemy near it up into the air
## (Launched) for a moment: a set-up for the next creature's Intro.

@export var radius: float = 56.0
## Longer than the swap cooldown, so the next swap can still cash it in (about 1 s to spare).
@export var launch_seconds: float = 2.5
@export var ring_scene: PackedScene


func guide_line() -> String:
	return "Leaves in a column of wind: every enemy within %d px is Airborne (%.1f s)." % [radius, launch_seconds]


func play(member: PlayableCreature, _partner: PlayableCreature) -> void:
	var spot := member.global_position
	for target_health in AbilityTargets.within(self, spot, radius):
		SetUp.apply(target_health, SetUp.LAUNCHED, launch_seconds)
	GaleCone.spawn(member.get_parent(), spot, Vector2.UP, radius * 0.6, 160.0)
	if ring_scene != null:
		Shockwave.spawn(ring_scene, member.get_parent(), spot, radius, 0.35, ApolloPalette.SKY_LIGHT)


func set_up_status() -> String:
	return SetUp.LAUNCHED
