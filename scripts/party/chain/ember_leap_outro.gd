class_name EmberLeapOutro
extends SwapMove
## Emberoo's Outro: he leaps out straight up in a column of flame, leaving a ring of fire
## that sets every enemy near him Burning: a set-up (Bloom on Burning is a Wildfire).

const LEAP_HEIGHT := 48.0
const LEAP_SECONDS := 0.3
const EMBERS: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.RED_LIGHT]

@export var radius: float = 42.0
@export var burn_seconds: float = 3.5


func play(member: PlayableCreature, _partner: PlayableCreature) -> void:
	var spot := member.global_position
	var world := member.get_parent()
	SwapFlourish.ghost(member, Vector2(0, -LEAP_HEIGHT), LEAP_SECONDS, ApolloPalette.ORANGE * 2.5)
	var flame := FlameArc.new()
	world.add_child(flame)
	flame.global_position = spot
	flame.play(Vector2.UP, 20.0, 70.0)
	Shockwave.spawn(HitFeel.RING_SCENE, world, spot, radius, 0.35, ApolloPalette.ORANGE)
	var embers := PixelDebris.spray(world, spot, EMBERS, 18, Vector2.UP, 60.0)
	embers.gravity = -30.0
	for target_health in AbilityTargets.within(self, spot, radius):
		SetUp.apply(target_health, SetUp.BURNING, burn_seconds)
