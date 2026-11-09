extends Node
## How far Emberoo has Awakened (registered as the "Awakening" autoload).
##
## Each Awakening is an evolution: Emberoo takes his next form (HeroFormSwitch: stage 1,
## then Emberoo, then his final form, each with its own art, size and reach), gains a flat
## stat bump (AwakeningBoost) and the Ember Tree opens its next ring. Reaching a level
## threshold (AwakeningStage) triggers it; `awakened` then plays the short evolve moment
## (AwakeningMoment on the creature, AwakeningAnnouncement on the HUD).
## Kept in an autoload so it survives the level restarting; SaveGame stores the stage.

## Any change of stage, including loading and the debug key (looks and stats follow it).
signal stage_changed(stage: int)
## Emberoo just Awakened to `stage` and the moment should play (a level up or the debug key).
signal awakened(stage: int)

## An AwakeningStage value.
var stage: int = AwakeningStage.NONE


func _ready() -> void:
	Progression.leveled_up.connect(_on_leveled_up)


## Sets the stage (DebugControls' F4). `celebrate` plays the awakening moment.
func set_stage(new_stage: int, celebrate: bool) -> void:
	new_stage = clampi(new_stage, AwakeningStage.NONE, AwakeningStage.LAST)
	if new_stage == stage:
		return
	stage = new_stage
	EmberTree.set_unlocked_stage(AwakeningStage.tree_stage_for(stage))
	# The moment starts first, so the look waits for its flare instead of switching now.
	if celebrate:
		awakened.emit(stage)
	stage_changed.emit(stage)


## What SaveGame writes.
func to_save_data() -> Dictionary:
	return {"stage": stage}


## Restores a save. A save from before Awakenings existed gets the stage its level has
## earned, so load Progression first. Opens the Ember Tree's rings without refunding
## anything: EmberTree's load, right after, learns the saved nodes again.
func load_save_data(data: Dictionary) -> void:
	var earned := AwakeningStage.for_level(Progression.level)
	stage = SaveData.read_int(data, "stage", earned, AwakeningStage.NONE, AwakeningStage.LAST)
	EmberTree.unlocked_stage = AwakeningStage.tree_stage_for(stage)
	stage_changed.emit(stage)


func _on_leveled_up(new_level: int) -> void:
	var earned := AwakeningStage.for_level(new_level)
	if earned > stage:
		set_stage(earned, true)
