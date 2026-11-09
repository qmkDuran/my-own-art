class_name ChainGuideReactionsPage
extends VBoxContainer
## The chain guide's reactions page: the reaction table, one row per reaction:
##   [Soaked]  +  FIRE  ->  Steam Burst   what it does, with real numbers
## Read from Reactions.TABLE and ReactionEffects.describe, so it can't drift from the game.
## Under it, every status with its icon and who on the team sets it up.

const REACTIONS_TITLE := "Reactions: a hit of one element on an enemy with a status"
const REACTION_HEADERS: Array[String] = ["ENEMY IS", "", "HIT BY", "", "REACTION", "WHAT IT DOES"]
const DESCRIPTION_WIDTH := 470.0
const USES_UP_NOTE := "Uses up the status."
const KEEPS_NOTE := "The status stays."
const STATUSES_TITLE := "Statuses and who sets them"
const STATUS_ORDER: Array[String] = [SetUp.BURNING, SetUp.SOAKED, SetUp.ROOTED, SetUp.LAUNCHED, SetUp.POISONED, SetUp.BROKEN]
const BROKEN_SOURCE := "anyone: keep hitting until its poise bar is empty"
const NOBODY := "nobody on the team yet"


func _init(members: Array[ChainGuideMember]) -> void:
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reactions_card())
	add_child(_statuses_card(members))


func _reactions_card() -> PanelContainer:
	var card := ChainGuideWidgets.make_card(ApolloPalette.CREAM)
	var column := ChainGuideWidgets.make_column()
	column.add_child(ChainGuideWidgets.make_section_title(REACTIONS_TITLE, ApolloPalette.GOLD))
	var grid := GridContainer.new()
	grid.columns = REACTION_HEADERS.size()
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for header in REACTION_HEADERS:
		grid.add_child(ChainGuideWidgets.make_label(header, ApolloPalette.GREY))
	for reaction in Reactions.TABLE:
		_add_reaction_row(grid, reaction)
	column.add_child(grid)
	card.add_child(column)
	return card


## [Soaked]  +  FIRE  ->  Steam Burst  what it does
func _add_reaction_row(grid: GridContainer, reaction: Dictionary) -> void:
	var element: String = reaction["element"]
	grid.add_child(ChainGuideWidgets.make_status_chip(reaction["status"]))
	grid.add_child(ChainGuideWidgets.make_label("+", ApolloPalette.GREY))
	grid.add_child(ChainGuideWidgets.make_label(element.to_upper(), ElementColors.for_element(element)))
	grid.add_child(ChainGuideIcon.arrow(ApolloPalette.GREY))
	grid.add_child(ChainGuideWidgets.make_label(reaction["name"], reaction["color"]))
	var note := USES_UP_NOTE if reaction["consumes"] else KEEPS_NOTE
	var description := ChainGuideWidgets.make_wrapped("%s %s" % [ReactionEffects.describe(reaction["id"]), note], ApolloPalette.GREY_LIGHT)
	description.custom_minimum_size.x = DESCRIPTION_WIDTH
	grid.add_child(description)


func _statuses_card(members: Array[ChainGuideMember]) -> PanelContainer:
	var card := ChainGuideWidgets.make_card(ApolloPalette.CREAM)
	var column := ChainGuideWidgets.make_column()
	column.add_child(ChainGuideWidgets.make_section_title(STATUSES_TITLE, ApolloPalette.GOLD))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for status_name in STATUS_ORDER:
		grid.add_child(ChainGuideWidgets.make_status_chip(status_name))
		grid.add_child(ChainGuideWidgets.make_label(_sources_of(status_name, members), ApolloPalette.GREY_LIGHT))
	column.add_child(grid)
	card.add_child(column)
	return card


## "Mossdillo W Bramble Snare, Ripfin swap out" for the moves that put `status_name` on.
static func _sources_of(status_name: String, members: Array[ChainGuideMember]) -> String:
	if status_name == SetUp.BROKEN:
		return BROKEN_SOURCE
	var sources: Array[String] = []
	for member in members:
		for row in member.skills:
			if row.set_up_status == status_name:
				sources.append("%s %s %s" % [member.display_name, row.keys, row.title])
		if member.outro_status == status_name:
			sources.append("%s %s" % [member.display_name, ChainGuideRecipes.SWAP_OUT])
	return ", ".join(sources) if not sources.is_empty() else NOBODY
