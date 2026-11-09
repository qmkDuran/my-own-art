class_name EmberLeapOutro
extends SwapMove
## Emberoo's Outro: he leaps out straight up in a column of flame, leaving a ring of fire
## that sets every enemy near him Burning: a set-up (Bloom on Burning is a Wildfire).

const LEAP_HEIGHT := 48.0
const LEAP_SECONDS := 0.3
const EMBERS: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.RED_LIGHT]
const EMBER_PIXELS := 18
## Embers float up instead of falling.
const EMBER_GRAVITY := -30.0
## The column of flame: how high it reaches (pixels) and how wide it fans out (degrees).
const FLAME_REACH := 20.0
const FLAME_ARC_DEGREES := 70.0

@export var radius: float = 42.0
@export var burn_seconds: float = 3.5


func guide_line() -> String:
	return "Leaps out in flame: every enemy within %d px is Burning (%.1f s)." % [radius, burn_seconds]


func play(member: PlayableCreature, _partner: PlayableCreature) -> void:
	var spot := member.global_position
	var world := member.get_parent()
	SwapFlourish.ghost(member, Vector2(0, -LEAP_HEIGHT), LEAP_SECONDS, ApolloPalette.ORANGE * 2.5)
	var flame := FlameArc.new()
	world.add_child(flame)
	flame.global_position = spot
	flame.play(Vector2.UP, FLAME_REACH, FLAME_ARC_DEGREES)
	Shockwave.spawn(HitFeel.RING_SCENE, world, spot, radius, 0.35, ApolloPalette.ORANGE)
	var embers := PixelDebris.spray(world, spot, EMBERS, EMBER_PIXELS, Vector2.UP, 60.0)
	embers.gravity = EMBER_GRAVITY
	for target_health in AbilityTargets.within(self, spot, radius):
		SetUp.apply(target_health, SetUp.BURNING, burn_seconds)


func set_up_status() -> String:
	return SetUp.BURNING
