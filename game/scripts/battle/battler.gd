class_name Battler
extends RefCounted
## A creature while it is in a battle: its stat stages, and for a wild one its mood and the Trust you have built.

var creature: Creature
var stages: Dictionary = {"atk": 0, "def": 0}
var wild: bool = false
var trust: int = 0
var mood: String = "wary"
var respected: bool = false


static func of(c: Creature, is_wild: bool = false) -> Battler:
	var b := Battler.new()
	b.creature = c
	b.wild = is_wild
	return b


func stage(stat: String) -> int:
	return int(stages[stat])


func shift_stage(stat: String, by: int) -> bool:
	var before: int = stage(stat)
	stages[stat] = BattleRules.clamp_stage(before + by)
	return stage(stat) != before


func hp_ratio() -> float:
	return float(creature.hp) / creature.max_hp()
