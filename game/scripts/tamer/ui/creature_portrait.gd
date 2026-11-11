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
	var src: Rect2 = _crop(path, tex, rec.species_id)
	var room: Vector2 = r.size - Vector2.ONE * PAD * 2.0
	var k: float = maxf(1.0, floorf(minf(room.x / src.size.x, room.y / src.size.y)))
	var size: Vector2 = src.size * k
	var at: Vector2 = (r.get_center() - size * 0.5).round()
	var tint: Color = Color(0.45, 0.45, 0.5) if rec.knocked_out() else Color.WHITE
	ci.draw_texture_rect_region(tex, Rect2(at, size), src, tint)


static func _crop(path: String, tex: Texture2D, species_id: String) -> Rect2:
	if not _crops.has(path):
		var meta: Dictionary = TamerData.sprites["creatures"][species_id]
		var frame := Rect2i(0, 0, int(meta["frame"][0]), int(meta["frame"][1]))
		var used: Rect2i = tex.get_image().get_region(frame).get_used_rect()
		_crops[path] = Rect2(used)
	return _crops[path]
