class_name AwakeningStage
extends RefCounted
## The Awakening stages and the levels that trigger them (the Awakening autoload holds
## which one Emberoo has reached). Each stage is an evolution form (HeroFormSwitch).

## Stage 1: Pyroo, the small one every run starts with.
const NONE := 0
## Awakening I: Pyroo grows into Emberoo, about the end of Act 1 (see Progression's XP curve).
const ONE := 1
## Awakening II: Emberoo grows into Cinderoo, flame mane and magma gauntlets (the mid game).
const TWO := 2
const LAST := TWO

## The level that triggers each Awakening.
const ONE_LEVEL := 10
const TWO_LEVEL := 25
const LEVEL_FOR_STAGE := {ONE: ONE_LEVEL, TWO: TWO_LEVEL}

const NUMERALS := {NONE: "", ONE: "I", TWO: "II"}
## The hero's name in each form: one evolution line, Pyroo → Emberoo → Cinderoo.
const HERO_NAMES := {NONE: "Pyroo", ONE: "Emberoo", TWO: "Cinderoo"}
## Stage 1 of the Ember Tree is open from the start; each Awakening opens the next ring.
const FIRST_TREE_STAGE := 1


## The Awakening a level has earned, e.g. ONE from level 10 on.
static func for_level(level: int) -> int:
	var earned := NONE
	for stage: int in LEVEL_FOR_STAGE:
		if level >= LEVEL_FOR_STAGE[stage]:
			earned = maxi(earned, stage)
	return earned


## The hero's name at Awakening `stage`, e.g. "Emberoo".
static func hero_name(stage: int) -> String:
	return HERO_NAMES[clampi(stage, NONE, LAST)]


## The hero's name in his current form.
static func current_hero_name() -> String:
	return hero_name(Awakening.stage)


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
