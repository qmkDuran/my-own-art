class_name ChainGuideIcon
extends Control
## A small pixel icon for the chain guide, blown up by a whole number so it stays crisp:
## a status icon (ChainStatusIcons), a texture (a skill icon or a creature's team icon,
## showing its middle `crop` pixels), or a pixel arrow pointing right.

enum Kind { STATUS, TEXTURE, ARROW }

## The arrow, as a text map ('#' filled).
const ARROW := [
	"....#..",
	"....##.",
	"#######",
	"....##.",
	"....#..",
]

var _kind: Kind = Kind.STATUS
var _status: String = ""
var _texture: Texture2D = null
var _crop: Vector2i = Vector2i.ZERO
var _pixel_size: int = 2
var _color: Color = ApolloPalette.CREAM


static func status(status_name: String, pixel_size: int = 2) -> ChainGuideIcon:
	var icon := ChainGuideIcon.new()
	icon._kind = Kind.STATUS
	icon._status = status_name
	icon._pixel_size = pixel_size
	icon.custom_minimum_size = Vector2.ONE * (ChainStatusIcons.SIZE + 2) * pixel_size
	return icon


## `crop` is the size of the middle part shown (zero shows the whole texture).
static func texture(source: Texture2D, pixel_size: int = 2, crop: Vector2i = Vector2i.ZERO) -> ChainGuideIcon:
	var icon := ChainGuideIcon.new()
	icon._kind = Kind.TEXTURE
	icon._texture = source
	icon._pixel_size = pixel_size
	var full := Vector2i(source.get_size()) if source != null else Vector2i.ZERO
	icon._crop = full if crop == Vector2i.ZERO else Vector2i(mini(crop.x, full.x), mini(crop.y, full.y))
	icon.custom_minimum_size = Vector2(icon._crop * pixel_size)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon


static func arrow(color: Color, pixel_size: int = 2) -> ChainGuideIcon:
	var icon := ChainGuideIcon.new()
	icon._kind = Kind.ARROW
	icon._color = color
	icon._pixel_size = pixel_size
	icon.custom_minimum_size = Vector2(ARROW[0].length(), ARROW.size()) * pixel_size
	return icon


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	match _kind:
		Kind.STATUS:
			ChainStatusIcons.draw(self, _status, Vector2.ZERO, _pixel_size)
		Kind.TEXTURE:
			_draw_texture()
		Kind.ARROW:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(_pixel_size, _pixel_size))
			PixelShape.draw_map(self, ARROW, {"#": _color}, Vector2.ZERO)
			draw_set_transform(Vector2.ZERO)


func _draw_texture() -> void:
	if _texture == null:
		return
	var full := Vector2i(_texture.get_size())
	var region := Rect2(Vector2((full - _crop) / 2), Vector2(_crop))
	draw_texture_rect_region(_texture, Rect2(Vector2.ZERO, Vector2(_crop * _pixel_size)), region)
