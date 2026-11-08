class_name EmberTreeScreen
extends CanvasLayer
## The in-game Ember Tree screen. K (or Tab) opens it; K, Tab or Escape closes it.
##
## Opening pauses the game; this layer keeps running (process mode Always) so the tree
## stays alive. Back to front: the tree view, the frame (vignette, header and footer bars),
## the stats card on the left and the side panel on the right. Everything is anchored to
## the screen's edges, and the opening zoom is worked out from the room left between them,
## so the layout fits whatever size the screen is. Learning goes through the EmberTree
## autoload; this only asks it.

## While open, the screen draws at a whole multiple of the game's own resolution, so its
## pixel font stays crisp (the hybrid approach in DESIGN.md): the smallest multiple at
## least this wide, which leaves the tree room between the two cards. The game's own
## scale comes back on close.
const MIN_UI_WIDTH := 960
## Space between the screen edge (or a bar) and the cards.
const PAGE_MARGIN := 12.0
const STATS_PANEL_WIDTH := 232.0
const SIDE_PANEL_WIDTH := 256.0
## Gap kept between the opening tree (Stage 1 and the branch names) and the bars and cards.
const TREE_FIT_MARGIN := 8.0
## The opening zoom never goes above this, however much room there is.
const MAX_START_ZOOM := 0.8
const FADE_SECONDS := 0.15
## Shown under the tree until the player zooms out: the later rings start off-screen.
const ZOOM_HINT := "Scroll out for Stage 2 and 3"

var is_open: bool = false

var _root: Control
var _view: EmberTreeView
var _frame: EmberTreeFrame
var _stats_panel: EmberTreeStatsPanel
var _side_panel: EmberTreeSidePanel
var _zoom_hint: Label
var _resolution := UiResolutionSwap.new()
var _paused_by_me: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_view()
	_frame = EmberTreeFrame.new()
	_root.add_child(_frame)
	_build_zoom_hint()
	_build_stats_panel()
	_build_side_panel()
	_root.visible = false
	_root.resized.connect(_on_resized)


func _exit_tree() -> void:
	if is_open:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("skill_tree"):
		toggle()
	elif is_open and event.is_action_pressed("ui_cancel"):
		close()
	else:
		return
	get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	_resolution.switch_to(get_window(), ui_size())
	_paused_by_me = not get_tree().paused
	get_tree().paused = true
	_frame.refresh_level()
	_stats_panel.preview_node("")
	_side_panel.show_node("")
	_fit_tree_at_home()
	_view.snap_home()
	_zoom_hint.modulate.a = 1.0
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


## The canvas size used while open (see MIN_UI_WIDTH), e.g. 960×540 for a 480×270 game.
static func ui_size() -> Vector2i:
	var game_size := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	return game_size * ceili(float(MIN_UI_WIDTH) / game_size.x)


# --- Layout -----------------------------------------------------------------------

func _build_root() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = EmberTreeFonts.ui_theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_view() -> void:
	_view = EmberTreeView.new()
	_view.node_hovered.connect(_on_node_hovered)
	_view.branch_hovered.connect(_on_branch_hovered)
	_view.zoom_changed.connect(_on_zoom_changed)
	_view.node_clicked.connect(func(id: String) -> void: EmberTree.learn(id))
	_view.node_right_clicked.connect(func(id: String) -> void: EmberTree.unlearn(id))
	_root.add_child(_view)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## A quiet line along the bottom of the tree area, between the two lower branches.
func _build_zoom_hint() -> void:
	_zoom_hint = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, ZOOM_HINT)
	_zoom_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zoom_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	_zoom_hint.offset_left = PAGE_MARGIN * 2.0 + STATS_PANEL_WIDTH
	_zoom_hint.offset_right = -(PAGE_MARGIN * 2.0 + SIDE_PANEL_WIDTH)
	_zoom_hint.offset_bottom = -(EmberTreeFrame.FOOTER_HEIGHT + TREE_FIT_MARGIN)
	_zoom_hint.offset_top = _zoom_hint.offset_bottom - EmberTreeFonts.TEXT_SIZE
	_root.add_child(_zoom_hint)


## Emberoo's stats, in the top-left corner under the header.
func _build_stats_panel() -> void:
	_stats_panel = EmberTreeStatsPanel.new(STATS_PANEL_WIDTH)
	_stats_panel.position = Vector2(PAGE_MARGIN, EmberTreeFrame.HEADER_HEIGHT + PAGE_MARGIN)
	_root.add_child(_stats_panel)


## The info and skill-points cards, down the right edge between the bars.
func _build_side_panel() -> void:
	_side_panel = EmberTreeSidePanel.new()
	_side_panel.size.x = SIDE_PANEL_WIDTH
	_side_panel.reset_pressed.connect(EmberTree.reset)
	_side_panel.anchor_left = 1.0
	_side_panel.anchor_right = 1.0
	_side_panel.anchor_bottom = 1.0
	_side_panel.offset_left = -(SIDE_PANEL_WIDTH + PAGE_MARGIN)
	_side_panel.offset_right = -PAGE_MARGIN
	_side_panel.offset_top = EmberTreeFrame.HEADER_HEIGHT + PAGE_MARGIN
	_side_panel.offset_bottom = -(EmberTreeFrame.FOOTER_HEIGHT + PAGE_MARGIN)
	_root.add_child(_side_panel)


## The part of the screen the tree has to itself: between the bars and the two cards.
func _tree_area() -> Rect2:
	var screen := _root.get_viewport_rect().size
	var left := PAGE_MARGIN * 2.0 + STATS_PANEL_WIDTH
	var right := screen.x - PAGE_MARGIN * 2.0 - SIDE_PANEL_WIDTH
	var top := EmberTreeFrame.HEADER_HEIGHT
	var bottom := screen.y - EmberTreeFrame.FOOTER_HEIGHT
	return Rect2(left, top, right - left, bottom - top).grow(-TREE_FIT_MARGIN)


## Picks the opening zoom and position so all of Stage 1 and the branch names sit
## inside the tree area.
func _fit_tree_at_home() -> void:
	var area := _tree_area()
	var bounds := EmberTreeLayout.opening_bounds()
	var zoom := minf(MAX_START_ZOOM, minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y))
	_view.home_zoom = zoom
	_view.home_centre = (area.get_center() - bounds.get_center() * zoom).round()


## A new screen size gets a new opening view.
func _on_resized() -> void:
	if not is_open:
		return
	_fit_tree_at_home()
	_view.snap_home()


func _on_node_hovered(id: String) -> void:
	_side_panel.show_node(id)
	_stats_panel.preview_node(id)


func _on_branch_hovered(branch: String) -> void:
	_side_panel.show_branch(branch)
	_stats_panel.preview_node("")


## The zoom hint fades away once the player has zoomed out past the opening view.
func _on_zoom_changed(zoom: float) -> void:
	var wanted_alpha := 0.0 if zoom < _view.home_zoom else 1.0
	create_tween().tween_property(_zoom_hint, "modulate:a", wanted_alpha, FADE_SECONDS)
