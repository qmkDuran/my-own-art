class_name CreaturePortrait
extends RefCounted
## A creature's face for the HUD and the camp panel: its first idle frame (shiny or not), cropped to the body, at a
## whole-number scale, centred in a framed box tinted by its element; greyed while it is knocked out.

const PAD: float = 3.0

static var _crops: Dictionary = {}       ## texture path -> the body's rect inside frame 0


static func draw_in(ci: CanvasItem, r: Rect2, rec: CreatureRecord) -> void:
	var el: String = rec.element()
	UiDraw.box(ci, r, Color(TamerData.color(el, "dark"), 0.55), TamerData.color(el, "core"))
	var path: String = "res://art/creatures/%s%s.png" % [rec.species_id, "_shiny" if rec.shiny else ""]
	var tex: Texture2D = PropSprite.tex(path)
	var src: Rect2 = crop(rec.species_id, rec.shiny)
	var room: Vector2 = r.size - Vector2.ONE * PAD * 2.0
	var fit: float = minf(room.x / src.size.x, room.y / src.size.y)
	var k: float = floorf(fit) if fit >= 1.0 else fit        # whole-pixel steps when it fits, else shrink to fit
	var size: Vector2 = src.size * k
	var at: Vector2 = (r.get_center() - size * 0.5).round()
	var tint: Color = Color(0.45, 0.45, 0.5) if rec.knocked_out() else Color.WHITE
	ci.draw_texture_rect_region(tex, Rect2(at, size), src, tint)


## Where the body is inside the first idle frame (also used to place tags above it).
static func crop(species_id: String, shiny: bool) -> Rect2:
	var path: String = "res://art/creatures/%s%s.png" % [species_id, "_shiny" if shiny else ""]
	var tex: Texture2D = PropSprite.tex(path)
	if not _crops.has(path):
		var meta: Dictionary = TamerData.sprites["creatures"][species_id]
		var frame := Rect2i(0, 0, int(meta["frame"][0]), int(meta["frame"][1]))
		var used: Rect2i = tex.get_image().get_region(frame).get_used_rect()
		_crops[path] = Rect2(used)
	return _crops[path]
