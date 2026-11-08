class_name EmberTreeLabelPainter
extends RefCounted
## Draws the Ember Tree's words: the branch names (which can be pointed at) and the
## captions that follow the curve of rings that have not opened yet.

const RING_CAPTION_SIZE := EmberTreeFonts.TEXT_SIZE
## Words written along a closed ring, per stage.
const RING_CAPTIONS := {2: "STAGE 2  ∙  EVOLVE TO UNLOCK", 3: "STAGE 3  ∙  ULTIMATES"}
## Where each stage's caption sits, in degrees: in the two upper gaps between branches,
## clear of the nodes (the lower gap would read upside down).
const RING_CAPTION_ANGLES := {2: [-30.0, -150.0], 3: [-30.0, -150.0]}

var _font: Font
## Branch -> the pill drawn behind its name while pointed at (built once, in its colour).
var _label_pills: Dictionary[String, StyleBoxFlat] = {}


func _init() -> void:
	_font = EmberTreeFonts.smooth()
	for branch: String in EmberTreeData.BRANCHES:
		_label_pills[branch] = _make_label_pill(EmberTreePalette.BRANCH_COLORS[branch])


## Says what each closed ring is, in small letters that follow the ring's curve.
func draw_ring_captions(canvas: CanvasItem) -> void:
	var radii := EmberTreeLayout.TIER_RADII
	for tier in radii.size():
		var stage := EmberTreeLayout.stage_of_tier(tier)
		if EmberTree.is_stage_open(stage) or not RING_CAPTIONS.has(stage) or EmberTreeLayout.stage_of_tier(tier - 1) == stage:
			continue
		for angle: float in RING_CAPTION_ANGLES[stage]:
			_draw_text_along_ring(canvas, RING_CAPTIONS[stage], radii[tier], deg_to_rad(angle), EmberTreePalette.GREY)


## Branch names look like something to point at: a faint underline at rest, and a lit pill
## in the branch's colour while pointed at.
func draw_branch_labels(canvas: CanvasItem, hovered_branch: String) -> void:
	var font_size := EmberTreeLayout.BRANCH_LABEL_SIZE
	for branch: String in EmberTreeData.BRANCHES:
		var text := EmberTreeLayout.branch_label_text(branch)
		var color: Color = EmberTreePalette.BRANCH_COLORS[branch]
		var is_hovered := branch == hovered_branch
		if is_hovered:
			canvas.draw_style_box(_label_pills[branch], EmberTreeLayout.branch_label_rect(branch))
		var text_width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var middle := EmberTreeLayout.branch_label_middle(branch)
		var baseline := middle + Vector2(-text_width / 2.0, font_size * EmberTreeFonts.CAP_HEIGHT_RATIO / 2.0)
		canvas.draw_string_outline(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, EmberTreePalette.BACKGROUND)
		canvas.draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color if is_hovered else Color(color, 0.85))
		if not is_hovered:  # the pill takes over from the underline
			var underline_y := baseline.y + 4.0
			canvas.draw_line(Vector2(middle.x - text_width / 2.0, underline_y), Vector2(middle.x + text_width / 2.0, underline_y), Color(color, 0.35), 1.5)


## Writes `text` centred on the ring at `middle_angle`, reading clockwise, one letter at a time.
func _draw_text_along_ring(canvas: CanvasItem, text: String, radius: float, middle_angle: float, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, RING_CAPTION_SIZE).x
	var travelled := -width / 2.0
	var half_cap := RING_CAPTION_SIZE * EmberTreeFonts.CAP_HEIGHT_RATIO / 2.0
	for letter_index in text.length():
		var letter := text.unicode_at(letter_index)
		var letter_width := _font.get_char_size(letter, RING_CAPTION_SIZE).x
		var angle := middle_angle + (travelled + letter_width / 2.0) / radius
		canvas.draw_set_transform(Vector2.from_angle(angle) * radius, angle + PI / 2.0)
		var baseline := Vector2(-letter_width / 2.0, half_cap)
		canvas.draw_char_outline(_font, baseline, String.chr(letter), RING_CAPTION_SIZE, 4, EmberTreePalette.BACKGROUND)
		canvas.draw_char(_font, baseline, String.chr(letter), RING_CAPTION_SIZE, color)
		travelled += letter_width
	canvas.draw_set_transform(Vector2.ZERO)


func _make_label_pill(color: Color) -> StyleBoxFlat:
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(EmberTreePalette.EMBER_DARK, 0.9)
	pill.border_color = Color(color, 0.7)
	pill.set_border_width_all(2)
	pill.set_corner_radius_all(6)
	return pill
