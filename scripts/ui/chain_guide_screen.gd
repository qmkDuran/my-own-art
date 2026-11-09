class_name ChainGuideScreen
extends CanvasLayer
## The chain guide (Project B's Team screen): Tab (or Esc) opens it and pauses the game;
## Tab or Esc closes it. Left/Right (or clicking a tab) turns the page:
##   Team       one card per team member: skills (key, icon, name, what it does in real
##              numbers, the status it sets up), its Signal Skill and exactly which status
##              fires it, and its swap-out move
##   Chains     how chaining works, and every chain this team can do
##   Reactions  element + status = reaction, what each does, and who sets each status up
##   Recruits   the wild creatures you can unbind later, with the same card
## Every word and number is read from the creatures' own nodes and the Reactions table
## (ChainGuideMember), so the guide can't drift from the game. This is the only place
## chain names appear: combat itself shows no words (see PROJECT_B.md).
## Like the Ember Tree it draws at 960×540 (UiResolutionSwap) so Monogram stays crisp.

enum Page { TEAM, CHAINS, REACTIONS, RECRUITS }

const TITLE := "TEAM GUIDE"
const SUBTITLE := "Skills, Signal Skills and chains"
## One per Page, in order.
const PAGE_NAMES: Array[String] = ["Team", "Chains", "Reactions", "Recruits"]
const FOOTER_HINT := "Tab / Esc: close   ∙   ← / →  or click a tab: turn the page   ∙   The game is paused"
const RECRUIT_SCENES: Array[String] = [
	"res://scenes/creatures/toxlop/toxlop.tscn",
	"res://scenes/creatures/zephoot/zephoot.tscn",
]
const RECRUITS_NOTE := "Wild recruits: not on your team yet. Unbind them in the field to add them."
const HEADER_HEIGHT := 52.0
const FOOTER_HEIGHT := 28.0
const MARGIN := 16
const CARD_GAP := 10
const CARDS_PER_ROW := 3
const HEADER_GAP := 12
const BACKDROP_ALPHA := 0.9
const FADE_SECONDS := 0.12
## Where each tab keeps its own plain look, to put back when it stops being the open page.
const PLAIN_STYLE_META := &"plain_style"

var is_open: bool = false
var page_index: int = 0

var _root: Control
var _tabs: Array[Button] = []
var _page_holder: MarginContainer
var _resolution := UiResolutionSwap.new()
var _paused_by_me: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = EmberTreeFonts.ui_theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_backdrop()
	_build_page_holder()
	_build_header()
	_build_footer()
	_root.visible = false


func _exit_tree() -> void:
	if is_open:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return
	if event.is_action_pressed("team_guide"):
		if is_open:
			close()
		elif not get_tree().paused and _party() != null:
			open()
		else:
			return
	elif not is_open:
		return
	elif event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("ui_right"):
		show_page(page_index + 1)
	elif event.is_action_pressed("ui_left"):
		show_page(page_index - 1)
	elif not event is InputEventKey:
		return
	# While open, every key stops here, so nothing behind the guide reacts to it.
	get_viewport().set_input_as_handled()


func open() -> void:
	if is_open:
		return
	is_open = true
	_resolution.switch_to(get_window(), EmberTreeScreen.ui_size())
	_paused_by_me = not get_tree().paused
	get_tree().paused = true
	show_page(page_index)
	_root.visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, FADE_SECONDS)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	_resolution.restore(get_window())
	if _paused_by_me:
		get_tree().paused = false


## Shows page `index` (wrapping around), rebuilt from the team as it is now.
func show_page(index: int) -> void:
	page_index = posmod(index, PAGE_NAMES.size())
	for child in _page_holder.get_children():
		_page_holder.remove_child(child)
		child.queue_free()
	_page_holder.add_child(_build_page(page_index))
	for tab_index in _tabs.size():
		_style_tab(_tabs[tab_index], tab_index == page_index)


func _build_page(index: int) -> Control:
	var team := _team_members()
	match index:
		Page.CHAINS:
			return ChainGuideChainsPage.new(team, _party().swap_cooldown)
		Page.REACTIONS:
			return ChainGuideReactionsPage.new(team + _recruit_members())
		Page.RECRUITS:
			return _recruits_page()
	return _card_row(team)


func _party() -> Party:
	return get_tree().get_first_node_in_group(Party.GROUP) as Party


func _team_members() -> Array[ChainGuideMember]:
	var members: Array[ChainGuideMember] = []
	var party := _party()
	for slot_index in party.members.size():
		members.append(ChainGuideMember.from_creature(party.members[slot_index], str(slot_index + 1)))
	return members


## The wild recruits not already on the team, read from their scenes.
func _recruit_members() -> Array[ChainGuideMember]:
	var on_team: Array[String] = []
	for creature in _party().members:
		on_team.append(creature.display_name)
	var recruits: Array[ChainGuideMember] = []
	for scene_path in RECRUIT_SCENES:
		var creature := (load(scene_path) as PackedScene).instantiate() as PlayableCreature
		if not on_team.has(creature.display_name):
			recruits.append(ChainGuideMember.from_creature(creature, ""))
		creature.free()
	return recruits


func _recruits_page() -> Control:
	var page := ChainGuideWidgets.make_column(CARD_GAP)
	page.add_child(ChainGuideWidgets.make_label(RECRUITS_NOTE, ApolloPalette.CREAM))
	page.add_child(_card_row(_recruit_members()))
	return page


## The members' cards side by side, CARDS_PER_ROW to a screen width.
func _card_row(members: Array[ChainGuideMember]) -> HBoxContainer:
	var row := ChainGuideWidgets.make_row(CARD_GAP)
	var gaps := CARD_GAP * (CARDS_PER_ROW - 1)
	var card_width := floorf((EmberTreeScreen.ui_size().x - MARGIN * 2 - gaps) / float(CARDS_PER_ROW))
	for member in members:
		var card := ChainGuideMemberCard.new(member, card_width)
		card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(card)
	return row


# --- Frame ------------------------------------------------------------------------

func _build_backdrop() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(EmberTreePalette.BACKGROUND, BACKDROP_ALPHA)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_page_holder() -> void:
	_page_holder = MarginContainer.new()
	_page_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page_holder.add_theme_constant_override("margin_left", MARGIN)
	_page_holder.add_theme_constant_override("margin_right", MARGIN)
	_page_holder.add_theme_constant_override("margin_top", int(HEADER_HEIGHT) + CARD_GAP)
	_page_holder.add_theme_constant_override("margin_bottom", int(FOOTER_HEIGHT) + CARD_GAP)
	_root.add_child(_page_holder)
	_page_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_header() -> void:
	var bar := _add_bar(Control.PRESET_TOP_WIDE, HEADER_HEIGHT)
	var row := ChainGuideWidgets.make_row(HEADER_GAP)
	var titles := ChainGuideWidgets.make_column(0)
	titles.add_child(ChainGuideWidgets.make_label(TITLE, EmberTreePalette.GOLD, EmberTreeFonts.LARGE_SIZE))
	titles.add_child(ChainGuideWidgets.make_label(SUBTITLE, EmberTreePalette.GREY))
	row.add_child(titles)
	row.add_child(ChainGuideWidgets.make_spacer())
	for tab_index in PAGE_NAMES.size():
		var tab := EmberTreeWidgets.make_button(PAGE_NAMES[tab_index])
		tab.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tab.pressed.connect(show_page.bind(tab_index))
		tab.set_meta(PLAIN_STYLE_META, tab.get_theme_stylebox("normal"))
		_tabs.append(tab)
		row.add_child(tab)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", MARGIN)
	margin.add_theme_constant_override("margin_right", MARGIN)
	margin.add_child(row)
	bar.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_footer() -> void:
	var bar := _add_bar(Control.PRESET_BOTTOM_WIDE, FOOTER_HEIGHT)
	var hint := ChainGuideWidgets.make_label(FOOTER_HINT, EmberTreePalette.GREY)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## A translucent bar across the screen at `edge` (a top- or bottom-wide preset).
func _add_bar(edge: Control.LayoutPreset, height: float) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = EmberTreePalette.BAR
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(bar)
	bar.set_anchors_and_offsets_preset(edge)
	if edge == Control.PRESET_TOP_WIDE:
		bar.offset_bottom = height
	else:
		bar.offset_top = -height
	return bar


## The open page's tab is gold and pressed-looking; the others are plain.
func _style_tab(tab: Button, is_current: bool) -> void:
	var color := EmberTreePalette.GOLD if is_current else EmberTreePalette.CREAM
	tab.add_theme_color_override("font_color", color)
	var plain_style: StyleBox = tab.get_meta(PLAIN_STYLE_META)
	tab.add_theme_stylebox_override("normal", tab.get_theme_stylebox("pressed") if is_current else plain_style)
