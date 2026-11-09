class_name BarkWardOutro
extends SwapMove
## Mossdillo's Outro: it curls up and rolls away, leaving its bark plates wrapped around the
## incoming teammate: a Bark Ward that soaks up the next hits whole for a few seconds.

const ROLL_AWAY := Vector2(-20, 0)
const ROLL_SECONDS := 0.25
const BARK: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK, ApolloPalette.GREEN]


func play(member: PlayableCreature, partner: PlayableCreature) -> void:
	SwapFlourish.ghost(member, ROLL_AWAY, ROLL_SECONDS, ApolloPalette.CORK * 2.0)
	PixelDebris.spray(member.get_parent(), member.global_position, BARK, 14, Vector2.UP, 160.0)
	if partner != null:
		BarkWard.wrap(partner)
