class_name BarkWardOutro
extends SwapMove
## Mossdillo's Outro: it curls up and rolls away, leaving its bark plates wrapped around the
## incoming teammate: a Bark Ward that soaks up the next hits whole for a few seconds.

const ROLL_AWAY := Vector2(-20, 0)
const ROLL_SECONDS := 0.25
const BARK: Array[Color] = [ApolloPalette.CORK, ApolloPalette.CORK_DARK, ApolloPalette.GREEN]
const BARK_PIXELS := 14


func guide_line() -> String:
	return "Rolls out, wraps the incoming teammate in Bark Ward: blocks the next %d hits (%d s)." % [BarkWard.HITS, BarkWard.SECONDS]


func play(member: PlayableCreature, partner: PlayableCreature) -> void:
	SwapFlourish.ghost(member, ROLL_AWAY, ROLL_SECONDS, ApolloPalette.CORK * 2.0)
	PixelDebris.spray(member.get_parent(), member.global_position, BARK, BARK_PIXELS, Vector2.UP, 160.0)
	if partner != null:
		BarkWard.wrap(partner)
