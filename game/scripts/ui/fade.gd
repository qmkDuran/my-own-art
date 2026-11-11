class_name Fade
extends RefCounted
## Screen fades between maps and into battle: a full-screen ink rect on the given layer.

const TIME: float = 0.25
const META: String = "fade_rect"


static func out(layer: CanvasLayer, colour: String = "ink") -> void:
	var r := ColorRect.new()
	r.color = UiKit.c(colour)
	r.color.a = 0.0
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	layer.set_meta(META, r)
	var tw: Tween = r.create_tween()
	tw.tween_property(r, "color:a", 1.0, 0.01 if Game.fast else TIME)
	await tw.finished


static func into(layer: CanvasLayer) -> void:
	if not layer.has_meta(META):
		return
	var r: ColorRect = layer.get_meta(META)
	layer.remove_meta(META)
	var tw: Tween = r.create_tween()
	tw.tween_property(r, "color:a", 0.0, 0.01 if Game.fast else TIME)
	await tw.finished
	r.queue_free()


## A quick double flash (wild creature leaps out).
static func flash(layer: CanvasLayer) -> void:
	for i: int in 2:
		await out(layer, "cream")
		await into(layer)
