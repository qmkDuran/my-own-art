class_name EmberTreeIcons
extends RefCounted
## The Ember Tree's node icons, and the padlock on sealed nodes.
##
## Each node shows its 14×14 pixel-art icon, art/skills/<node id>_icon.png (the same art
## the HUD's skill slots use). It is drawn at a whole number of screen pixels per icon
## pixel, whatever the tree's zoom, and snapped to the screen's pixel grid, so it stays
## crisp; it is centred by its drawn pixels, not its image box, so lopsided icons still
## look centred in their frame.

const ICON_PATH := "res://art/skills/%s_icon.png"
## An icon is at most this many times its frame's radius across, so it fits inside the
## diamond or circle with the frame's edge still showing around it.
const MAX_SIZE_PER_RADIUS := 1.5

const LOCK_FILLED := "#"
const LOCK_PIXELS := ["..###..", ".#...#.", ".#...#.", "#######", "###.###", "###.###", "#######"]

## Node id -> {"normal": its icon, "greyed": its greyed twin, "middle": the middle of its
## drawn pixels, in icon pixels}; empty when the node has no icon file. Built on first use.
static var _icons: Dictionary = {}


## Draws `node_id`'s icon centred on `centre`, as large as fits a frame `frame_radius`
## across (both in `canvas` units); `greyed` as SkillIconPixels.greyed() shows it.
static func draw(canvas: CanvasItem, node_id: String, centre: Vector2, frame_radius: float, greyed: bool, tint: Color) -> void:
	var icon := _icon(node_id)
	if icon.is_empty():
		return
	var texture: Texture2D = icon["greyed" if greyed else "normal"]
	# Canvas units -> real window pixels: the tree's zoom and pan, then the window's stretch.
	var to_screen := canvas.get_viewport().get_final_transform() * canvas.get_screen_transform()
	var screen_per_unit := to_screen.get_scale().x
	var image_size := Vector2(texture.get_size())
	var screen_pixels_per_icon_pixel := maxf(1.0, floorf(frame_radius * MAX_SIZE_PER_RADIUS * screen_per_unit / image_size.x))
	var icon_pixel := screen_pixels_per_icon_pixel / screen_per_unit
	var drawn_middle: Vector2 = icon["middle"]
	var top_left_on_screen := (to_screen * (centre - drawn_middle * icon_pixel)).round()
	var top_left := to_screen.affine_inverse() * top_left_on_screen
	canvas.draw_texture_rect(texture, Rect2(top_left, image_size * icon_pixel), false, tint)


## The small padlock glyph, centred on `centre`, `pixel_size` per glyph pixel.
static func draw_lock(canvas: CanvasItem, centre: Vector2, pixel_size: float, color: Color) -> void:
	var glyph_size := Vector2(LOCK_PIXELS[0].length(), LOCK_PIXELS.size())
	var top_left := centre - glyph_size * pixel_size / 2.0
	for y in LOCK_PIXELS.size():
		for x in LOCK_PIXELS[y].length():
			if LOCK_PIXELS[y][x] == LOCK_FILLED:
				canvas.draw_rect(Rect2(top_left + Vector2(x, y) * pixel_size, Vector2.ONE * pixel_size), color)


static func _icon(node_id: String) -> Dictionary:
	if not _icons.has(node_id):
		_icons[node_id] = _load(node_id)
	return _icons[node_id]


static func _load(node_id: String) -> Dictionary:
	var path := ICON_PATH % node_id
	if not ResourceLoader.exists(path):
		push_warning("Ember Tree: no icon at %s" % path)
		return {}
	var texture: Texture2D = load(path)
	var image := texture.get_image()
	var used := Rect2(image.get_used_rect())
	return {"normal": texture, "greyed": _greyed(image), "middle": used.get_center()}


static func _greyed(image: Image) -> ImageTexture:
	var grey := Image.create_empty(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	var pixels := SkillIconPixels.greyed(PixelShape.from_image(image))
	for pixel: Vector2i in pixels:
		grey.set_pixelv(pixel, pixels[pixel])
	return ImageTexture.create_from_image(grey)
