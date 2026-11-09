class_name HeroFxScale
extends RefCounted
## How big the hero's attack effects are drawn (Art direction v2, DESIGN.md: Emberoo grows
## from a 16 px sprite to ~35/46/63 px by evolution stage, and his attacks must be flashy).
##
## Effects with their own size (the jab impact, crits, the Ash Guard wall, the Ember Hop
## landing) are drawn for the ~46 px hero directly. Effects whose size a skill hands them
## (Flame Uppercut's reach, the Spinning Hook's radius) still get numbers measured for the
## old 16 px Emberoo, so they draw that size times SKILL_SIZE_SCALE.
##
## HERO INTEGRATION: when the skills' reach and radius numbers are scaled up for the new
## hero, set SKILL_SIZE_SCALE to 1.0 (otherwise the flames are drawn twice too big).

const SKILL_SIZE_SCALE := 2.0
