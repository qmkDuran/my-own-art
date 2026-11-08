class_name SkillSlot
extends Control
## One 18×18 skill slot in the bottom bar: a stone frame, the key letter (Q W E R) in the corner,
## the skill's icon, and while the skill recovers a dark veil with the seconds left.
##
## The slot flashes white → gold → orange when its skill is used (with the trainer's shout),
## and flashes dimly when a skill is refused because it's still recovering.
## The skill is any Resource with an `icon: Texture2D` (see SkillBarHud); none = an empty slot.

signal hovered(slot: SkillSlot)
signal unhovered(slot: SkillSlot)

const SLOT_SIZE := 18
## The inner area (inside the frame and its dark line), where the icon and the veil go.
const INNER := Rect2i(2, 2, 14, 14)
## Icon colours at least this bright turn light grey while recovering; the rest dark grey.
const BRIGHT_ICON_LUMINANCE := 0.785
## Border colour for each step of the "used" flash (one step per shout stage).
const USED_FLASH_COLORS: Array[Color] = [HudPalette.WHITE, HudPalette.GOLD, HudPalette.ORANGE_DARK]
const REFUSED_FLASH_SECONDS := 0.25

## Icon pixels per texture, so images are read only once: {texture: {pixel: Color}}.
static var _icon_pixel_cache: Dictionary = {}

@export var key_label: String = "Q"

## The skill in this slot (a Skill resource), or null.
var skill: Resource:
	set(value):
		if value != skill:
			skill = value
			queue_redraw()

var _cooldown_left: float = 0.0
var _cooldown_fraction: float = 0.0
var _used_flash_time: float = -1.0
var _refused_flash_left: float = 0.0


func _ready() -> void:
	size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(func() -> void: hovered.emit(self))
	mouse_exited.connect(func() -> void: unhovered.emit(self))


func _process(delta: float) -> void:
	if _used_flash_time >= 0.0:
		_used_flash_time += delta
		if _used_flash_stage() >= USED_FLASH_COLORS.size():
			_used_flash_time = -1.0
		queue_redraw()
	if _refused_flash_left > 0.0:
		_refused_flash_left = maxf(0.0, _refused_flash_left - delta)
		queue_redraw()


## Seconds left and the share of the cooldown still to go (1 = just used, 0 = ready).
func set_cooldown(seconds_left: float, fraction_left: float) -> void:
	var fraction := clampf(fraction_left, 0.0, 1.0)
	if is_equal_approx(seconds_left, _cooldown_left) and is_equal_approx(fraction, _cooldown_fraction):
		return
	_cooldown_left = maxf(0.0, seconds_left)
	_cooldown_fraction = fraction
	queue_redraw()


## The skill was just used: flash in step with the trainer's shout.
func flash_used() -> void:
	_used_flash_time = 0.0
	queue_redraw()


## The skill was refused because it's still recovering: a short, dim flash.
func flash_refused() -> void:
	_refused_flash_left = REFUSED_FLASH_SECONDS
	queue_redraw()


func is_recovering() -> bool:
	return _cooldown_left > 0.0


func _draw() -> void:
	_draw_frame()
	if _used_flash_stage() == 0:
		_draw_inner_glint()
	var icon := _icon()
	if icon != null:
		_draw_icon(icon)
	if is_recovering():
		_draw_cooldown_veil()
	var key_color := HudPalette.GREY if is_recovering() else HudPalette.CREAM
	PixelFont.draw_text(self, key_label, Vector2(INNER.position), key_color, HudPalette.OUTLINE)
	_draw_flash_border()


## Dark outline, stone frame lit on the top and left, a dark line, then a two-tone inside.
func _draw_frame() -> void:
	draw_rect(Rect2(-1, -1, SLOT_SIZE + 2, SLOT_SIZE + 2), HudPalette.OUTLINE)
	draw_rect(Rect2(0, 0, SLOT_SIZE, SLOT_SIZE), HudPalette.STONE)
	draw_rect(Rect2(0, 0, SLOT_SIZE - 1, 1), HudPalette.STONE_LIGHT)
	draw_rect(Rect2(0, 0, 1, SLOT_SIZE - 1), HudPalette.STONE_LIGHT)
	draw_rect(Rect2(1, 1, SLOT_SIZE - 2, SLOT_SIZE - 2), HudPalette.OUTLINE)
	var inner := Rect2(INNER)
	var top_half := Rect2(inner.position, Vector2(inner.size.x, floorf(inner.size.y / 2.0)))
	draw_rect(inner, HudPalette.DARK)
	draw_rect(top_half, HudPalette.SLATE)


## First frame of the "used" flash: a bright line along the inside top and left edges.
func _draw_inner_glint() -> void:
	draw_rect(Rect2(INNER.position.x, INNER.position.y, INNER.size.x, 1), HudPalette.STONE)
	draw_rect(Rect2(INNER.position.x, INNER.position.y, 1, INNER.size.y), HudPalette.STONE)


## The icon, centred (nudged one pixel down-right, clear of the key letter), with an outline.
## While recovering it turns grey.
func _draw_icon(icon: Texture2D) -> void:
	var icon_size := Vector2i(icon.get_size())
	var top_left := Vector2((SLOT_SIZE - icon_size.x) / 2 + 1, (SLOT_SIZE - icon_size.y) / 2 + 1)
	var pixels := _icon_pixels(icon)
	if is_recovering():
		pixels = _greyed(pixels)
	PixelShape.draw_outlined(self, pixels, top_left, HudPalette.OUTLINE)


## A dotted veil over the share still recovering, a sky-blue line on its edge, and the seconds left.
func _draw_cooldown_veil() -> void:
	var veil_rows := roundi(INNER.size.y * _cooldown_fraction)
	var edge_row := mini(INNER.position.y + veil_rows, INNER.end.y - 1)
	var parity := roundi(global_position.x + global_position.y)
	for y in range(INNER.position.y, edge_row):
		for x in range(INNER.position.x, INNER.end.x):
			if (x + y + parity) % 2 == 0:
				PixelShape.draw_pixel(self, Vector2(x, y), HudPalette.NIGHT)
	draw_rect(Rect2(INNER.position.x, edge_row, INNER.size.x, 1), HudPalette.SKY)
	var seconds := str(ceili(_cooldown_left))
	var left := (SLOT_SIZE - PixelFont.width_of(seconds)) / 2
	var top := (SLOT_SIZE - PixelFont.GLYPH_HEIGHT) / 2 + 1
	PixelFont.draw_text(self, seconds, Vector2(left, top), HudPalette.WHITE, HudPalette.OUTLINE)


## The frame's outer ring takes the flash colour while a flash is showing.
func _draw_flash_border() -> void:
	var color: Color
	var stage := _used_flash_stage()
	if stage >= 0 and stage < USED_FLASH_COLORS.size():
		color = USED_FLASH_COLORS[stage]
	elif _refused_flash_left > 0.0:
		color = HudPalette.GREY
	else:
		return
	draw_rect(Rect2(0, 0, SLOT_SIZE, 1), color)
	draw_rect(Rect2(0, SLOT_SIZE - 1, SLOT_SIZE, 1), color)
	draw_rect(Rect2(0, 0, 1, SLOT_SIZE), color)
	draw_rect(Rect2(SLOT_SIZE - 1, 0, 1, SLOT_SIZE), color)


## Which step of the "used" flash is showing (0, 1, 2), or -1 when none is.
func _used_flash_stage() -> int:
	if _used_flash_time < 0.0:
		return -1
	return int(_used_flash_time / HudTrainer.SHOUT_STAGE_SECONDS)


func _icon() -> Texture2D:
	if skill == null:
		return null
	return skill.get("icon") as Texture2D


static func _icon_pixels(icon: Texture2D) -> Dictionary:
	if not _icon_pixel_cache.has(icon):
		var image := icon.get_image()
		_icon_pixel_cache[icon] = PixelShape.from_image(image) if image != null else {}
	return _icon_pixel_cache[icon]


static func _greyed(pixels: Dictionary) -> Dictionary:
	var grey := {}
	for pixel: Vector2i in pixels:
		var color: Color = pixels[pixel]
		grey[pixel] = HudPalette.STONE_LIGHT if color.get_luminance() >= BRIGHT_ICON_LUMINANCE else HudPalette.STONE
	return grey
