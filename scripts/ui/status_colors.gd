class_name StatusColors
extends RefCounted
## The colour of each element's status effect, shared by everything that shows one: tick
## numbers, the HUD heart's tick, the HUD status icons and the tint pulse on the target.
## Built from the Apollo palette (see ApolloPalette).

const BURN := ApolloPalette.ORANGE
## Toxic: poison.
const POISON := ApolloPalette.GREEN_LIGHT
const POISON_DARK := ApolloPalette.GREEN
## Stone: stagger.
const STAGGER := ApolloPalette.CORK
const STAGGER_LIGHT := ApolloPalette.CREAM
## What a hit with no element shows in.
const DIRECT := ApolloPalette.WHITE


## The colour of a tick of this damage type (e.g. green for poison).
static func for_damage_type(damage_type: Health.DamageType) -> Color:
	match damage_type:
		Health.DamageType.BURN:
			return BURN
		Health.DamageType.POISON:
			return POISON
	return DIRECT
