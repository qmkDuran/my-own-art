class_name HeroFxScale
extends RefCounted
## How big the hero's attack effects are drawn (Art direction v2, DESIGN.md: Emberoo grows
## to ~35/46/63 px by evolution form, and his attacks must be flashy).
##
## Effects with their own size (the jab impact, crits, the Ash Guard wall, the Ember Hop
## landing) are drawn for the ~46 px hero directly. Effects whose size a skill hands them
## (Flame Uppercut's reach, the Spinning Hook's radius) draw that size times SKILL_SIZE_SCALE.
## The skills' numbers now come from the hero's evolution form (HeroForm) and are the real
## hit areas, so the scale is 1: the flame and the fire ring cover exactly what they hit.

const SKILL_SIZE_SCALE := 1.0
