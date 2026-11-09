class_name ChainGuideChainsPage
extends VBoxContainer
## The chain guide's chains page: how chaining works, then every chain the team can do.
##   rules   three steps (set up, card lights, swap) and the Link meter, with real numbers
##   chains  [Mossdillo] W Bramble Snare -> [Rooted] -> [2] Ripfin -> Drown
## The chains come from ChainGuideRecipes, so they can't drift from the game.

const CHAINS_TITLE := "Chains to try"
const RULES_TITLE := "How chaining works"
const CHAIN_COLUMNS := 10
const PAGE_GAP := 10
const RULE_GAP := 4
const CHAIN_COLUMN_GAP := 5
const CHAIN_ROW_GAP := 6
## Gap between a creature's small sprite and its name.
const TAG_GAP := 4


func _init(members: Array[ChainGuideMember], swap_cooldown: float) -> void:
	add_theme_constant_override("separation", PAGE_GAP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rules_card(swap_cooldown))
	add_child(_chains_card(members))


func _rules_card(swap_cooldown: float) -> PanelContainer:
	var card := ChainGuideWidgets.make_card(ApolloPalette.GOLD)
	var column := ChainGuideWidgets.make_column(RULE_GAP)
	column.add_child(ChainGuideWidgets.make_section_title(RULES_TITLE, ApolloPalette.GOLD))
	column.add_child(_rule("1", "Use a skill that sets a status on enemies (look for its icon)."))
	column.add_child(_rule("2", "A teammate who can cash it in lights up: its card glows and shows that status icon."))
	column.add_child(_rule("3", "Press its key: it swaps in and fires its Signal Skill. Element + status = a reaction."))
	var link_rule := "Full LINK meter: the next Signal Skill is a Link Finisher (x%d dmg, slow-mo). Every hit takes %ss off all cooldowns; swaps are %ss apart." % [
			SignalSkill.LINK_DAMAGE_MULTIPLIER, ElementStrike.COOLDOWN_SHAVE_PER_HIT, ChainGuideWidgets.short_number(swap_cooldown)]
	column.add_child(_rule("+", link_rule))
	card.add_child(column)
	return card


func _rule(number: String, text: String) -> HBoxContainer:
	var row := ChainGuideWidgets.make_row()
	row.add_child(ChainGuideWidgets.make_key_cap(number, ApolloPalette.CREAM))
	row.add_child(ChainGuideWidgets.make_wrapped(text, ApolloPalette.CREAM))
	return row


func _chains_card(members: Array[ChainGuideMember]) -> PanelContainer:
	var card := ChainGuideWidgets.make_card(ApolloPalette.CREAM)
	var column := ChainGuideWidgets.make_column()
	column.add_child(ChainGuideWidgets.make_section_title(CHAINS_TITLE, ApolloPalette.GOLD))
	var grid := ChainGuideWidgets.make_grid(CHAIN_COLUMNS, CHAIN_COLUMN_GAP, CHAIN_ROW_GAP)
	for recipe in ChainGuideRecipes.find(members):
		_add_chain_row(grid, recipe)
	column.add_child(grid)
	card.add_child(column)
	return card


## [icon] Mossdillo  W  Bramble Snare  ->  [Rooted]  ->  2 [icon] Ripfin  ->  Drown
func _add_chain_row(grid: GridContainer, recipe: ChainGuideRecipes.Recipe) -> void:
	grid.add_child(_creature_tag(recipe.setter))
	grid.add_child(ChainGuideWidgets.make_key_cap(recipe.move_keys) if not recipe.move_keys.is_empty() else _empty())
	grid.add_child(ChainGuideWidgets.make_label(recipe.move_name, ApolloPalette.CREAM))
	grid.add_child(ChainGuideIcon.arrow(ApolloPalette.GREY))
	grid.add_child(ChainGuideWidgets.make_status_chip(recipe.status))
	grid.add_child(ChainGuideIcon.arrow(ApolloPalette.GREY))
	grid.add_child(ChainGuideWidgets.make_key_cap(recipe.receiver.swap_key) if not recipe.receiver.swap_key.is_empty() else _empty())
	grid.add_child(_creature_tag(recipe.receiver))
	grid.add_child(ChainGuideIcon.arrow(ApolloPalette.GREY))
	if recipe.reaction == null:
		grid.add_child(ChainGuideWidgets.make_label(recipe.receiver.signal_name, ElementColors.for_element(recipe.receiver.element)))
	else:
		grid.add_child(ChainGuideWidgets.make_label(recipe.reaction.display_name, recipe.reaction.color))


## A creature's small sprite and name in its element colour.
func _creature_tag(member: ChainGuideMember) -> HBoxContainer:
	var tag := ChainGuideWidgets.make_row(TAG_GAP)
	if member.icon != null:
		tag.add_child(ChainGuideIcon.texture(member.icon, 1, ChainGuideMemberCard.PORTRAIT_CROP))
	tag.add_child(ChainGuideWidgets.make_label(member.display_name, ElementColors.for_element(member.element)))
	return tag


func _empty() -> Control:
	var empty := Control.new()
	empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return empty
