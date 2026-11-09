class_name WhirlpoolOutro
extends SwapMove
## Ripfin's Outro: it dives into the ground and leaves a whirlpool that drags nearby enemies
## in for a moment and soaks them: a set-up (Fire on Soaked is a Steam Burst). The
## whirlpool keeps working after Ripfin has left the field.

const DIVE_DEPTH := 8.0
const DIVE_SECONDS := 0.2
const SPLASH: Array[Color] = [ApolloPalette.SKY, ApolloPalette.SKY_LIGHT, ApolloPalette.WHITE, ApolloPalette.CORK]


func guide_line() -> String:
	return "Dives out: a whirlpool (%.1f s) pulls in enemies within %d px and Soaks them (%d s)." % [Whirlpool.SECONDS, Whirlpool.RADIUS, Whirlpool.SOAK_SECONDS]


func play(member: PlayableCreature, _partner: PlayableCreature) -> void:
	var world := member.get_parent()
	SwapFlourish.ghost(member, Vector2(0, DIVE_DEPTH), DIVE_SECONDS, ApolloPalette.SKY_LIGHT * 2.0)
	PixelDebris.spray(world, member.global_position, SPLASH, 20, Vector2.UP, 120.0)
	Whirlpool.spawn(world, member.global_position)


func set_up_status() -> String:
	return SetUp.SOAKED
