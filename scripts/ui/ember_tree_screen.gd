class_name EmberTreeScreen
extends PausingScreen
## The in-game Ember Tree screen (a PausingScreen). K (or Tab) opens it; K, Tab or Escape
## closes it.
##
## Back to front: the tree view, the frame (vignette, header and footer bars),
## the stats card on the left and the side panel on the right (placed by EmberTreeScreenLayout).
## The opening zoom is worked out from the room left between them, so the layout fits whatever
## size the screen is. Learning goes through the EmberTree autoload; this only asks it.

## The opening zoom never goes above this, however much room there is.
const MAX_START_ZOOM := 0.8
## Shown under the tree until the player zooms out: the later rings start off-screen.
const ZOOM_HINT := "Scroll out for Stage 2 and 3"
const ZOOM_HINT_FADE_SECONDS := 0.15

var _view: EmberTreeView
var _frame: EmberTreeFrame
var _stats_panel: EmberTreeStatsPanel
var _side_panel: EmberTreeSidePanel
var _zoom_hint: Label


func _ready() -> void:
	super._ready()
	_build_view()
	_frame = EmberTreeFrame.new()
	_root.add_child(_frame)
	_build_zoom_hint()
	_build_stats_panel()
	_build_side_panel()
	_root.resized.connect(_on_resized)


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


func _on_open() -> void:
	_frame.refresh_level()
	_stats_panel.preview_node("")
	_side_panel.show_node("")
	_fit_tree_at_home()
	_view.snap_home()
	_zoom_hint.modulate.a = 1.0


# --- Layout -----------------------------------------------------------------------

func _build_view() -> void:
	_view = EmberTreeView.new()
	_view.node_hovered.connect(_on_node_hovered)
	_view.branch_hovered.connect(_on_branch_hovered)
	_view.zoom_changed.connect(_on_zoom_changed)
	_view.node_clicked.connect(func(id: String) -> void: EmberTree.learn(id))
	_view.node_right_clicked.connect(func(id: String) -> void: EmberTree.unlearn(id))
	_root.add_child(_view)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_zoom_hint() -> void:
	_zoom_hint = UiLabel.make(EmberTreeFonts.TEXT_SIZE, EmberTreePalette.GREY, ZOOM_HINT)
	EmberTreeScreenLayout.place_zoom_hint(_zoom_hint)
	_root.add_child(_zoom_hint)


func _build_stats_panel() -> void:
	_stats_panel = EmberTreeStatsPanel.new(EmberTreeScreenLayout.STATS_PANEL_WIDTH)
	EmberTreeScreenLayout.place_stats_panel(_stats_panel)
	_root.add_child(_stats_panel)


func _build_side_panel() -> void:
	_side_panel = EmberTreeSidePanel.new()
	_side_panel.reset_pressed.connect(EmberTree.reset)
	EmberTreeScreenLayout.place_side_panel(_side_panel)
	_root.add_child(_side_panel)


## Picks the opening zoom and position so all of Stage 1 and the branch names sit
## inside the tree area.
func _fit_tree_at_home() -> void:
	var area := EmberTreeScreenLayout.tree_area(_root.get_viewport_rect().size)
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
	create_tween().tween_property(_zoom_hint, "modulate:a", wanted_alpha, ZOOM_HINT_FADE_SECONDS)
