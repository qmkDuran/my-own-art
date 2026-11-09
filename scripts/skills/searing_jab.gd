class_name SearingJab
extends Node
## Searing Jab (Ember Tree, Inferno): once its node is learned, every jab and Spinning Hook
## that lands sets the enemy Burning. Flame Uppercut doesn't burn.
##
## A passive, so it has no slot: it listens to MeleeAttack's `target_hit`. Its numbers fill
## the Searing Jab and Kindling facts in the tree (see EmberTreeSkillFacts) and the stats
## panel's Burn row, so they are only written here. With Kindling learned, burns last
## `kindling_multiplier` times as long.

## The Kindling node's id (Ember Tree, Inferno).
const KINDLING_ID := "kindling"

@export var melee_attack: MeleeAttack
## Damage a burn deals each second.
@export var burn_damage: int = 1
## How long a burn lasts without Kindling, in seconds.
@export var burn_duration: float = 3.0
## How many times longer burns last with Kindling.
@export var kindling_multiplier: float = 2.0

## Seconds added to every burn on top (e.g. a "Burn lasts +1s" chip, see ChipEffects).
var bonus_burn_seconds: float = 0.0

## How long a burn lasts with Kindling, in seconds (shown in Kindling's facts).
var kindled_duration: float:
	get:
		return burn_duration * kindling_multiplier


func _ready() -> void:
	melee_attack.target_hit.connect(_on_target_hit)


## Whether Searing Jab is learned in the Ember Tree (this node's name is its skill action).
func is_unlocked() -> bool:
	return EmberTree.is_skill_unlocked(name)


## How long a burn lasts right now, counting Kindling and chip bonuses.
func current_burn_duration() -> float:
	var duration := kindled_duration if EmberTree.is_learned(KINDLING_ID) else burn_duration
	return duration + bonus_burn_seconds


func _on_target_hit(target_health: Health) -> void:
	if is_unlocked():
		Burning.apply_to(target_health, burn_damage, current_burn_duration())
