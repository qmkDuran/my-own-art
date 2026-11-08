class_name SkillSlot
extends Control
## One 18×18 skill slot in the bottom bar: a stone frame, the key letter in the corner,
## the skill's icon and its Heat cost in the bottom-right corner.
##
## States: while the skill can't be used (recovering, or not enough Heat) the icon is greyed,
## and while recovering a dark veil shows the seconds left. The moment it can be used again it
## glows gold → orange for a moment (with a ring around the slot), then stays in full colour
## with a gold top edge. It also flashes white → gold → orange when used (with the trainer's
## shout), and dimly when refused because it's still recovering. Whenever its key is pressed
## (used or refused) the contents dip a pixel, like a pressed button.
## The skill is any Resource with an `icon: Texture2D` and a `heat_cost: int` (see SkillBarHud);
## none = an empty slot.

signal hovered(slot: SkillSlot)
signal unhovered(slot: SkillSlot)

const SLOT_SIZE := 18
## The inner area (inside the frame and its dark line), where the icon and the veil go.
const INNER := Rect2i(2, 2, 14, 14)
## Top of the cooldown seconds (centred across the slot, clear of the Heat badge below).
const SECONDS_TOP := 7

## The letter of the key that fires this slot (SkillBarHud reads it from the InputMap).
var key_label: String = "":
	set(value):
		if value != key_label:
			key_label = value
			queue_redraw()

## The skill in this slot (a Skill resource), or null.
var skill: Resource:
	set(value):
		if value != skill:
			skill = value
			_was_usable = is_usable()
			queue_redraw()

## Whether there is enough Heat for the skill (SkillBarHud keeps this up to date).
var has_enough_heat: bool = true:
	set(value):
		if value != has_enough_heat:
			has_enough_heat = value
			_on_usable_maybe_changed()

var _cooldown_left: float = 0.0
var _cooldown_fraction: float = 0.0
var _flashes := SkillSlotFlashes.new()
var _was_usable: bool = false


func _ready() -> void:
	size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(func() -> void: hovered.emit(self))
	mouse_exited.connect(func() -> void: unhovered.emit(self))


func _process(delta: float) -> void:
	if _flashes.advance(delta):
		queue_redraw()


## Seconds left and the share of the cooldown still to go (1 = just used, 0 = ready).
func set_cooldown(seconds_left: float, fraction_left: float) -> void:
	var seconds := maxf(0.0, seconds_left)
	var fraction := clampf(fraction_left, 0.0, 1.0)
	# Compared exactly, not with is_equal_approx: a cooldown counted down in 1/60 s steps can
	# end a hair above zero (about 1e-15 s) for one frame. An approximate check would then
	# skip the final 0.0, and the slot would stay "recovering" with a 1 on it for good.
	if seconds == _cooldown_left and fraction == _cooldown_fraction:
		return
	_cooldown_left = seconds
	_cooldown_fraction = fraction
	_on_usable_maybe_changed()


## The skill was just used: flash in step with the trainer's shout.
func flash_used() -> void:
	_flashes.start_used()
	queue_redraw()


## The key was pressed (used or refused): the contents dip a pixel for a moment.
func press_down() -> void:
	_flashes.start_press()
	queue_redraw()


## The skill was refused because it's still recovering: a short, dim flash.
func flash_refused() -> void:
	_flashes.start_refused()
	queue_redraw()


func is_recovering() -> bool:
	return _cooldown_left > 0.0


## Whether pressing the key would fire the skill: it has recovered and there is enough Heat.
func is_usable() -> bool:
	return skill != null and not is_recovering() and has_enough_heat


## Starts the "ready" glow when the skill turns usable again.
func _on_usable_maybe_changed() -> void:
	var usable := is_usable()
	if usable and not _was_usable:
		_flashes.start_ready()
	_was_usable = usable
	queue_redraw()


func _draw() -> void:
	_draw_frame()
	if _flashes.used_stage() == 0:
		_draw_inner_glint()
	draw_set_transform(_flashes.press_offset())
	var icon := _icon()
	if icon != null:
		_draw_icon(icon)
	if is_recovering():
		_draw_cooldown_veil()
	if skill != null:
		HeatCostBadge.draw(self, _heat_cost(), has_enough_heat, INNER.end - Vector2i.ONE)
	if is_recovering():
		_draw_seconds_left()
	var key_color := ApolloPalette.CREAM if is_usable() or skill == null else ApolloPalette.GREY
	PixelFont.draw_text(self, key_label, Vector2(INNER.position), key_color, ApolloPalette.OUTLINE)
	draw_set_transform(Vector2.ZERO)
	_flashes.draw_border(self, SLOT_SIZE)


## The stone frame (with a gold top edge while usable), then a two-tone inside.
func _draw_frame() -> void:
	PixelShape.draw_stone_frame(self, SLOT_SIZE)
	if is_usable():
		draw_rect(Rect2(0, 0, SLOT_SIZE - 1, 1), ApolloPalette.GOLD)
	var inner := Rect2(INNER)
	var top_half := Rect2(inner.position, Vector2(inner.size.x, floorf(inner.size.y / 2.0)))
	draw_rect(inner, ApolloPalette.DARK)
	draw_rect(top_half, ApolloPalette.SLATE)


## First frame of the "used" flash: a bright line along the inside top and left edges.
func _draw_inner_glint() -> void:
	draw_rect(Rect2(INNER.position.x, INNER.position.y, INNER.size.x, 1), ApolloPalette.STONE)
	draw_rect(Rect2(INNER.position.x, INNER.position.y, 1, INNER.size.y), ApolloPalette.STONE)


## The icon with an outline, centred in the inner area: greyed while it can't be used, and
## lit up (a bright silhouette, then a coloured outline) during the "ready" glow.
func _draw_icon(icon: Texture2D) -> void:
	var pixels := SkillIconPixels.of(icon, INNER)
	var outline := ApolloPalette.OUTLINE
	var glow_stage := _flashes.ready_stage()
	if not is_usable():
		pixels = SkillIconPixels.greyed(pixels)
	elif glow_stage == 0:
		pixels = SkillIconPixels.flashed(pixels, _flashes.ready_color())
	elif glow_stage > 0:
		outline = _flashes.ready_color()
	PixelShape.draw_outlined(self, pixels, Vector2.ZERO, outline)


## A dotted veil over the share still recovering, with a sky-blue line on its edge.
func _draw_cooldown_veil() -> void:
	var veil_rows := roundi(INNER.size.y * _cooldown_fraction)
	var edge_row := mini(INNER.position.y + veil_rows, INNER.end.y - 1)
	var parity := roundi(global_position.x + global_position.y)
	for y in range(INNER.position.y, edge_row):
		for x in range(INNER.position.x, INNER.end.x):
			if (x + y + parity) % 2 == 0:
				PixelShape.draw_pixel(self, Vector2(x, y), ApolloPalette.NIGHT)
	draw_rect(Rect2(INNER.position.x, edge_row, INNER.size.x, 1), ApolloPalette.SKY)


func _draw_seconds_left() -> void:
	var seconds := str(ceili(_cooldown_left))
	var left := (SLOT_SIZE - PixelFont.width_of(seconds)) / 2
	PixelFont.draw_text(self, seconds, Vector2(left, SECONDS_TOP), ApolloPalette.WHITE, ApolloPalette.OUTLINE)


func _icon() -> Texture2D:
	if skill == null:
		return null
	return skill.get("icon") as Texture2D


func _heat_cost() -> int:
	if skill == null:
		return 0
	var cost: Variant = skill.get("heat_cost")
	return cost if cost is int else 0
