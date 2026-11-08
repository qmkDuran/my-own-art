class_name EmberTreeVeins
extends RefCounted
## The flame veins between Ember Tree nodes: which ones exist, how far fire has run along
## each, and how they are drawn. A vein fills with fire when both its ends are lit.
##
## Drawn by EmberTreeCanvas, in tree space, behind every node.

const CENTRE_ID := EmberTreeLayout.CENTRE_ID
const FILL_SECONDS := 0.4
const DRAIN_SECONDS := 0.25
const SPARKS := 6
const SPARK_SPEED := 0.5

## [from_id, to_id] for every vein, inner end first.
var _veins: Array[PackedStringArray] = []
## "from>to" -> 0..1, how far fire has travelled along the vein.
var _fill: Dictionary[String, float] = {}
var _positions: Dictionary[String, Vector2]


## `positions` maps every node id (and CENTRE_ID) to where it sits in tree space.
func _init(positions: Dictionary[String, Vector2]) -> void:
	_positions = positions
	for node in EmberTreeData.all_nodes():
		var sources: PackedStringArray = node.requires if not node.requires.is_empty() else PackedStringArray([CENTRE_ID])
		for source in sources:
			_veins.append(PackedStringArray([source, node.id]))


## Brings every vein in line with what is learned. With `animate` off, they snap; with it
## on, fire runs out along new veins (and drains back) using tweens made on `owner`.
func sync(owner: Node, animate: bool) -> void:
	for vein in _veins:
		var key := _key(vein)
		var target := 1.0 if _is_lit(vein[0]) and _is_lit(vein[1]) else 0.0
		var current: float = _fill.get(key, 0.0)
		if not animate:
			_fill[key] = target
		elif not is_equal_approx(current, target):
			var seconds := FILL_SECONDS if target > current else DRAIN_SECONDS
			var tween := owner.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_method(func(fill: float) -> void: _fill[key] = fill, current, target, seconds)


## Draws every vein; those leading into `highlighted_branch` get a soft glow in `glow`.
func draw(canvas: CanvasItem, time: float, highlighted_branch: String, glow: Color) -> void:
	for vein in _veins:
		var node := EmberTreeData.find(vein[1])
		_draw_vein(canvas, vein, time, node.branch == highlighted_branch, glow)


func _draw_vein(canvas: CanvasItem, vein: PackedStringArray, time: float, is_highlighted: bool, glow: Color) -> void:
	var from := _positions[vein[0]]
	var to := _positions[vein[1]]
	if is_highlighted:
		canvas.draw_line(from, to, Color(glow, 0.3), 8.0)
	canvas.draw_line(from, to, EmberTreePalette.COAL, 3.0)
	var fill: float = _fill.get(_key(vein), 0.0)
	if fill <= 0.0:
		return
	var burning_end := from.lerp(to, fill)
	canvas.draw_line(from, burning_end, Color(EmberTreePalette.RED, 0.7), 6.0)
	canvas.draw_line(from, burning_end, EmberTreePalette.GOLD, 2.0)
	# Sparks travel along the burning part.
	for spark in SPARKS:
		var along := fmod(time * SPARK_SPEED + float(spark) / SPARKS, 1.0) * fill
		var point := from.lerp(to, along)
		canvas.draw_rect(Rect2(point.round() - Vector2(1.5, 1.5), Vector2(3, 3)), EmberTreePalette.CREAM)


func _is_lit(id: String) -> bool:
	return id == CENTRE_ID or EmberTree.is_learned(id)


func _key(vein: PackedStringArray) -> String:
	return "%s>%s" % [vein[0], vein[1]]
