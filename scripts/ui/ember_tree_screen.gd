class_name EmberTreeScreen
extends CanvasLayer
## The in-game Ember Tree screen. K (or Tab) opens it; K, Tab or Escape closes it.
##
## Opening pauses the game; this layer keeps running (process mode Always) so the tree
## stays alive. Builds the layout, back to front: tree view, vignette, header and footer
## bars, side panel. Learning goes through the EmberTree autoload; this only asks it.


## The world renders at 320×180; this screen uses 640×360 while open so text stays crisp
## (the hybrid approach in DESIGN.md). The game's own scale comes back on close.
const UI_SIZE := Vector2i(640, 360)
## Space between the screen edge (or a bar) and content, in UI pixels.
const PAGE_MARGIN := 16.0
const HEADER_HEIGHT := 48.0
const FOOTER_HEIGHT := 30.0
const SIDE_PANEL_WIDTH := 220.0
## Header text is lifted this much so it looks centred (the font leaves room above capitals).
const HEADER_TEXT_LIFT := 2.0
## Gap kept between the opening tree (Stage 1 and the branch names) and the bars and panel.
const TREE_FIT_MARGIN := 8.0
## The opening zoom never goes above this, however much room there is.
const MAX_START_ZOOM := 0.8
const FADE_SECONDS := 0.15
const FOOTER_HINT := "Click: ignite   ·   Right-click: put out   ·   Scroll: zoom   ·   Drag: move   ·   K / Esc: close"
## Shown under the tree until the player zooms out: the later rings start off-screen.
const ZOOM_HINT := "Scroll out for Stage 2 and 3"
const ZOOM_HINT_HEIGHT := 14.0

var is_open: bool = false

var _root: Control
var _view: EmberTreeView
var _side_panel: EmberTreeSidePanel
var _level_label: Label
var _xp_label: Label
var _zoom_hint: Label
var _saved_scale_size: Vector2i
var _saved_scale_mode: Window.ContentScaleMode
var _saved_scale_aspect: Window.ContentScaleAspect
var _paused_by_me: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_view()
	_build_vignette()
	_build_header()
	_build_footer()
	_build_zoom_hint()
	_build_side_panel()
	_root.visible = false


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
	_use_crisp_ui_resolution()
	_paused_by_me = not get_tree().paused
	get_tree().paused = true
	_refresh_level()
	_view.snap_home()
	_zoom_hint.modulate.a = 1.0
	_side_panel.show_node("")
	_root.visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, FADE_SECONDS)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	_restore_game_resolution()
	if _paused_by_me:
		get_tree().paused = false


# --- Resolution -----------------------------------------------------------------

func _use_crisp_ui_resolution() -> void:
	var window := get_window()
	_saved_scale_size = window.content_scale_size
	_saved_scale_mode = window.content_scale_mode
	_saved_scale_aspect = window.content_scale_aspect
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_size = UI_SIZE
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _restore_game_resolution() -> void:
	var window := get_window()
	window.content_scale_size = _saved_scale_size
	window.content_scale_mode = _saved_scale_mode
	window.content_scale_aspect = _saved_scale_aspect


# --- Layout -----------------------------------------------------------------------

func _build_root() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)


func _build_view() -> void:
	_view = EmberTreeView.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fit_tree_at_home()
	_view.node_hovered.connect(func(id: String) -> void: _side_panel.show_node(id))
	_view.branch_hovered.connect(func(branch: String) -> void: _side_panel.show_branch(branch))
	_view.zoom_changed.connect(_on_zoom_changed)
	_view.node_clicked.connect(func(id: String) -> void: EmberTree.learn(id))
	_view.node_right_clicked.connect(func(id: String) -> void: EmberTree.unlearn(id))
	_root.add_child(_view)


## Darkens the screen edges so the eye goes to the middle and the fire glows.
func _build_vignette() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([Color(EmberTreePalette.BACKGROUND, 0.0), Color(EmberTreePalette.BACKGROUND, 0.15), Color(EmberTreePalette.BACKGROUND, 0.75)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.05, 1.05)
	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(vignette)


func _build_header() -> void:
	_add_bar(Rect2(0, 0, UI_SIZE.x, HEADER_HEIGHT), HEADER_HEIGHT)
	var title_block := VBoxContainer.new()
	title_block.alignment = BoxContainer.ALIGNMENT_CENTER
	title_block.add_theme_constant_override("separation", 0)
	title_block.position = Vector2(PAGE_MARGIN, -HEADER_TEXT_LIFT)
	title_block.size = Vector2(SIDE_PANEL_WIDTH, HEADER_HEIGHT)
	title_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(title_block)
	title_block.add_child(_make_label("EMBEROO", 16, EmberTreePalette.GOLD))
	title_block.add_child(_make_label("The Ember Tree", 10, EmberTreePalette.GREY))
	# Right side: the level, and how far it is to the next one (which brings a skill point).
	var level_block := VBoxContainer.new()
	level_block.alignment = BoxContainer.ALIGNMENT_CENTER
	level_block.add_theme_constant_override("separation", 0)
	level_block.position = Vector2(UI_SIZE.x - SIDE_PANEL_WIDTH - PAGE_MARGIN, -HEADER_TEXT_LIFT)
	level_block.size = Vector2(SIDE_PANEL_WIDTH, HEADER_HEIGHT)
	level_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(level_block)
	_level_label = _make_label("", 13, EmberTreePalette.CREAM)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_block.add_child(_level_label)
	_xp_label = _make_label("", 9, EmberTreePalette.GREY)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_block.add_child(_xp_label)


func _build_footer() -> void:
	var top := UI_SIZE.y - FOOTER_HEIGHT
	_add_bar(Rect2(0, top, UI_SIZE.x, FOOTER_HEIGHT), top)
	var hint := _add_label(Rect2(PAGE_MARGIN, top, UI_SIZE.x - PAGE_MARGIN * 2, FOOTER_HEIGHT), 9, EmberTreePalette.GREY, HORIZONTAL_ALIGNMENT_CENTER)
	hint.text = FOOTER_HINT


## A quiet line in the empty gap below Emberoo, between the two lower branches.
func _build_zoom_hint() -> void:
	var bottom := UI_SIZE.y - FOOTER_HEIGHT - TREE_FIT_MARGIN
	_zoom_hint = _add_label(Rect2(0, bottom - ZOOM_HINT_HEIGHT, _tree_area_width(), ZOOM_HINT_HEIGHT), 9, EmberTreePalette.GREY, HORIZONTAL_ALIGNMENT_CENTER)
	_zoom_hint.text = ZOOM_HINT


func _build_side_panel() -> void:
	_side_panel = EmberTreeSidePanel.new()
	_side_panel.position = Vector2(UI_SIZE.x - SIDE_PANEL_WIDTH - PAGE_MARGIN, HEADER_HEIGHT + PAGE_MARGIN)
	_side_panel.size = Vector2(SIDE_PANEL_WIDTH, UI_SIZE.y - HEADER_HEIGHT - FOOTER_HEIGHT - PAGE_MARGIN * 2)
	_side_panel.reset_pressed.connect(EmberTree.reset)
	_root.add_child(_side_panel)


## The width left for the tree, between the left edge and the side panel.
func _tree_area_width() -> float:
	return UI_SIZE.x - SIDE_PANEL_WIDTH - PAGE_MARGIN


## Picks the opening zoom and position so all of Stage 1 and the branch names sit
## between the header, the footer and the side panel, with a small margin.
func _fit_tree_at_home() -> void:
	var area := Rect2(0, HEADER_HEIGHT, _tree_area_width(), UI_SIZE.y - HEADER_HEIGHT - FOOTER_HEIGHT).grow(-TREE_FIT_MARGIN)
	var bounds := EmberTreeCanvas.opening_bounds()
	var zoom := minf(MAX_START_ZOOM, minf(area.size.x / bounds.size.x, area.size.y / bounds.size.y))
	_view.home_zoom = zoom
	_view.home_centre = area.get_center() - bounds.get_center() * zoom


func _refresh_level() -> void:
	_level_label.text = "Level %d" % Progression.level
	if Progression.level >= Progression.MAX_LEVEL:
		_xp_label.text = "Max level"
	else:
		_xp_label.text = "%d / %d XP  ·  next skill point at Level %d" % [Progression.xp, Progression.xp_to_next(), Progression.level + 1]


## The zoom hint fades away once the player has zoomed out past the opening view.
func _on_zoom_changed(zoom: float) -> void:
	var wanted_alpha := 0.0 if zoom < _view.home_zoom else 1.0
	create_tween().tween_property(_zoom_hint, "modulate:a", wanted_alpha, FADE_SECONDS)


## A translucent bar with a thin warm line along its tree-facing edge (at `line_y`).
func _add_bar(rect: Rect2, line_y: float) -> void:
	var bar := ColorRect.new()
	bar.color = EmberTreePalette.BAR
	bar.position = rect.position
	bar.size = rect.size
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	var line := ColorRect.new()
	line.color = Color(EmberTreePalette.ORANGE, 0.25)
	line.position = Vector2(0, line_y)
	line.size = Vector2(UI_SIZE.x, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(line)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_label(rect: Rect2, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := _make_label("", font_size, color)
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	_root.add_child(label)
	return label
