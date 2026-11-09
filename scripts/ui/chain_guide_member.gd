class_name ChainGuideMember
extends RefCounted
## Everything the chain guide (Tab) shows about one team creature, read off the creature's
## own nodes: its SkillBar actions (name, icon, cooldown, `guide_line`), its Intro (the
## Signal Skill and the statuses that fire it) and its Outro. The numbers come from the
## very values the game plays with, so the guide can't drift from the code.

const SLOT_KEYS: Array[String] = ["Q", "W", "E", "R"]
## A front-view creature's basic attack is slot 0: right mouse or Q.
const BASIC_SLOT_KEYS := "RMB/Q"
## Emberoo's basic attack is his jab combo (MeleeAttack), right mouse only.
const JAB_KEYS := "RMB"
const JAB_TITLE := "Jab"
const LOCKED_NOTE := "Learn it in the Ember Tree (K)."


## One skill row: the keys that fire it, its name, icon and what it does.
class SkillRow:
	var keys: String = ""
	var title: String = ""
	var icon: Texture2D = null
	var text: String = ""
	var cooldown: float = 0.0
	## The status it puts on enemies ("" for none).
	var set_up_status: String = ""
	var is_locked: bool = false


## What fires the Signal Skill: an enemy carrying any of `statuses`, and the reaction the
## creature's element sets off on them ({} when it is just the Signal Skill's own hit).
## Statuses with the same result share one Trigger, so the card stays short.
class Trigger:
	var statuses: Array[String] = []
	var reaction: Dictionary = {}


var display_name: String = ""
var element: String = ""
var icon: Texture2D = null
## "1", "2" or "3" for a team member (its swap key); "" for a recruit.
var swap_key: String = ""
var skills: Array[SkillRow] = []
var signal_name: String = ""
var signal_line: String = ""
var triggers: Array[Trigger] = []
var outro_line: String = ""
var outro_status: String = ""


static func from_creature(creature: PlayableCreature, swap_key: String) -> ChainGuideMember:
	var member := ChainGuideMember.new()
	member.display_name = creature.display_name
	member.element = creature.element
	member.icon = creature.team_icon
	member.swap_key = swap_key
	member._read_skills(creature)
	member._read_signal(creature.get_node_or_null(Party.INTRO_NODE) as SignalSkill)
	member._read_outro(creature.get_node_or_null(Party.OUTRO_NODE) as SwapMove)
	return member


func has_signal_skill() -> bool:
	return not signal_name.is_empty()


func _read_skills(creature: PlayableCreature) -> void:
	var actions := _skill_actions(creature)
	var has_basic_slot := actions.any(func(action: SkillAction) -> bool: return action.slot_index == 0)
	var melee := creature.get_node_or_null("MeleeAttack") as MeleeAttack
	if not has_basic_slot and melee != null:
		skills.append(_jab_row(melee))
	for action in actions:
		skills.append(_skill_row(action))


## The creature's skill actions, in slot order (Q, W, E, R).
func _skill_actions(creature: PlayableCreature) -> Array[SkillAction]:
	var actions: Array[SkillAction] = []
	var skill_bar := creature.get_node_or_null("SkillBar")
	if skill_bar == null:
		return actions
	for child in skill_bar.get_children():
		if child is SkillAction and (child as SkillAction).skill != null:
			actions.append(child as SkillAction)
	actions.sort_custom(func(a: SkillAction, b: SkillAction) -> bool: return a.slot_index < b.slot_index)
	return actions


func _skill_row(action: SkillAction) -> SkillRow:
	var row := SkillRow.new()
	row.keys = BASIC_SLOT_KEYS if action.slot_index == 0 else SLOT_KEYS[action.slot_index]
	row.title = action.skill.display_name
	row.icon = action.skill.icon
	row.cooldown = action.skill.cooldown
	row.set_up_status = action.set_up_status()
	row.is_locked = not EmberTree.is_skill_unlocked(action.name)
	row.text = action.guide_line()
	if row.is_locked:
		row.text += " " + LOCKED_NOTE
	return row


func _jab_row(melee: MeleeAttack) -> SkillRow:
	var row := SkillRow.new()
	row.keys = JAB_KEYS
	row.title = JAB_TITLE
	row.text = melee.guide_line()
	return row


func _read_signal(intro: SignalSkill) -> void:
	if intro == null:
		return
	signal_name = intro.signal_name
	signal_line = intro.guide_line()
	for status_name in intro.trigger_statuses:
		var reaction := Reactions.find_for_status(status_name, element)
		_trigger_for(reaction).statuses.append(status_name)


## The trigger with this result, made on first use.
func _trigger_for(reaction: Dictionary) -> Trigger:
	for trigger in triggers:
		if trigger.reaction.get("id", "") == reaction.get("id", ""):
			return trigger
	var trigger := Trigger.new()
	trigger.reaction = reaction
	triggers.append(trigger)
	return trigger


func _read_outro(outro: SwapMove) -> void:
	if outro == null:
		return
	outro_line = outro.guide_line()
	outro_status = outro.set_up_status()
