class_name AwakeningBoost
extends Node
## The flat stat bump each Awakening gives Emberoo: more max health and a harder jab.
##
## Remembers how much it has added, so loading, the level restarting and the debug key
## (which can also lower the stage) always end up with exactly the current stage's bonus.

## Added for every Awakening reached (Awakening II has twice Awakening I's bonus).
const HEALTH_PER_AWAKENING := 3
const JAB_DAMAGE_PER_AWAKENING := 1

@export var health: Health
@export var melee_attack: MeleeAttack

## Awakenings whose bonus is applied right now.
var _applied_stage: int = 0


func _ready() -> void:
	_apply(Awakening.stage)
	Awakening.stage_changed.connect(_apply)


## The bonus at `stage` in words, e.g. "+3 health, +1 jab", for the Ember Tree's stats.
static func bonus_text(stage: int) -> String:
	return "+%d health, +%d jab" % [HEALTH_PER_AWAKENING * stage, JAB_DAMAGE_PER_AWAKENING * stage]


func _apply(stage: int) -> void:
	var change := stage - _applied_stage
	if change == 0:
		return
	health.change_max_health(HEALTH_PER_AWAKENING * change)
	melee_attack.damage += JAB_DAMAGE_PER_AWAKENING * change
	_applied_stage = stage
