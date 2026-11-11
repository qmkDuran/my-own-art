class_name Stats
extends RefCounted
## Stat formulas: species base values grow linearly with level. Kept in one place so balance is easy to tune.

const HP_SCALE: float = 10.0
const HP_FLAT: int = 10
const STAT_SCALE: float = 20.0
const STAT_FLAT: int = 5


static func hp(base: int, level: int) -> int:
	return int(base * level / HP_SCALE) + level + HP_FLAT


static func other(base: int, level: int) -> int:
	return int(base * level / STAT_SCALE) + STAT_FLAT
