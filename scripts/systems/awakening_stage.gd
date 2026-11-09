class_name AwakeningStage
extends RefCounted
## The Awakening stages and the levels that trigger them (the Awakening autoload holds
## which one Emberoo has reached). Stage 2 of the old evolution plan is now Awakening I.

const NONE := 0
## Awakening I, "Blue Flame": about the end of Act 1 (see Progression's XP curve).
const ONE := 1
## Awakening II: darker still, a richer blue flame and a quiet aura (the mid game).
const TWO := 2
const LAST := TWO

## The level that triggers each Awakening.
const ONE_LEVEL := 10
const TWO_LEVEL := 25
const LEVEL_FOR_STAGE := {ONE: ONE_LEVEL, TWO: TWO_LEVEL}

const NAMES := {NONE: "Not awakened", ONE: "Blue Flame", TWO: "Blue Inferno"}
const NUMERALS := {NONE: "", ONE: "I", TWO: "II"}
## Stage 1 of the Ember Tree is open from the start; each Awakening opens the next ring.
const FIRST_TREE_STAGE := 1


## The Awakening a level has earned, e.g. ONE from level 10 on.
static func for_level(level: int) -> int:
	var earned := NONE
	for stage: int in LEVEL_FOR_STAGE:
		if level >= LEVEL_FOR_STAGE[stage]:
			earned = maxi(earned, stage)
	return earned


## "Awakening I" (or "" for NONE).
static func title_of(stage: int) -> String:
	if stage <= NONE:
		return ""
	return "Awakening %s" % NUMERALS[stage]


## The Ember Tree ring (its stage) an Awakening opens.
static func tree_stage_for(stage: int) -> int:
	return FIRST_TREE_STAGE + stage


## The Awakening that opens an Ember Tree ring.
static func for_tree_stage(tree_stage: int) -> int:
	return tree_stage - FIRST_TREE_STAGE
