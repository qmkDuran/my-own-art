class_name ChainGuideRecipes
extends RefCounted
## Works out the "chains to try" for a team: every way one member sets up a status (a
## skill, or its Outro on swap-out) that another member's Signal Skill cashes in. Read
## from the members' own data, so a new creature's chains show up by themselves.

const SWAP_OUT := "swap out"


## One chain: `setter` uses `move` (keys + name), leaving `status` on enemies; swapping
## to `receiver` fires its Signal Skill, or a reaction (`reaction`, {} for none).
class Recipe:
	var setter: ChainGuideMember
	var move_keys: String = ""
	var move_name: String = ""
	var status: String = ""
	var receiver: ChainGuideMember
	var reaction: Dictionary = {}


## Every chain within `members`: reaction chains first, then plain Signal Skill set-ups.
static func find(members: Array[ChainGuideMember]) -> Array[Recipe]:
	var with_reaction: Array[Recipe] = []
	var signal_only: Array[Recipe] = []
	for receiver in members:
		for trigger in receiver.triggers:
			for setter in members:
				if setter == receiver:
					continue
				for status_name in trigger.statuses:
					for recipe in _recipes_for(setter, receiver, status_name, trigger.reaction):
						(signal_only if recipe.reaction.is_empty() else with_reaction).append(recipe)
	return with_reaction + signal_only


static func _recipes_for(setter: ChainGuideMember, receiver: ChainGuideMember, status_name: String,
		reaction: Dictionary) -> Array[Recipe]:
	var found: Array[Recipe] = []
	for row in setter.skills:
		if row.set_up_status == status_name:
			found.append(_recipe(setter, row.keys, row.title, receiver, status_name, reaction))
	if setter.outro_status == status_name:
		found.append(_recipe(setter, "", SWAP_OUT, receiver, status_name, reaction))
	return found


static func _recipe(setter: ChainGuideMember, keys: String, move_name: String, receiver: ChainGuideMember,
		status_name: String, reaction: Dictionary) -> Recipe:
	var recipe := Recipe.new()
	recipe.setter = setter
	recipe.move_keys = keys
	recipe.move_name = move_name
	recipe.status = status_name
	recipe.receiver = receiver
	recipe.reaction = reaction
	return recipe
