class_name SkillSlot
extends Control
## One 20×20 skill slot in the bottom bar: a stone frame, the key letter in the corner,
## the skill's icon and its Heat cost in the bottom-right corner.
##
## States: while the skill can't be used (recovering, or not enough Heat) the icon is greyed,
## and while recovering a dark veil shows the seconds left. The moment it can be used again it
## glows gold → orange for a moment (with a ring around the slot), then stays in full colour
## with a gold top edge. It also flashes white → gold → orange when used (with the trainer's
## shout), and dimly when refused because it's still recovering. Whenever its key is pressed
## (used or refused) the contents dip a pixel, like a pressed button.
## The skill is any Resource with an `icon: Texture2D` and a `heat_cost: int` (see SkillBarHud);
## none = an empty slot. SkillSlotPainter draws the frame, the veil and the seconds.

signal hovered(slot: SkillSlot)
signal unhovered(slot: SkillSlot)

const SLOT_SIZE := 20
## The inner area (inside the frame and its dark line), where the icon and the veil go:
## room for a 14×14 icon, its added outline and nothing more, so the icon sits exactly
## in the middle.
const INNER := Rect2i(2, 2, 16, 16)
## The key letter's top-left and the Heat badge's last pixel: on the frame's dark inner line,
## a pixel out from the inner area, so they cover as little of the icon as they can.
const KEY_LABEL_TOP_LEFT := Vector2i(1, 1)
const HEAT_BADGE_BOTTOM_RIGHT := Vector2i(SLOT_SIZE - 2, SLOT_SIZE - 2)

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
	SkillSlotPainter.draw_frame(self, is_usable())
	if _flashes.used_stage() == 0:
		SkillSlotPainter.draw_inner_glint(self)
	draw_set_transform(_flashes.press_offset())
	var icon := _icon()
	if icon != null:
		_draw_icon(icon)
	if is_recovering():
		SkillSlotPainter.draw_cooldown_veil(self, _cooldown_fraction)
	if skill != null:
		HeatCostBadge.draw(self, _heat_cost(), has_enough_heat, HEAT_BADGE_BOTTOM_RIGHT)
	if is_recovering():
		SkillSlotPainter.draw_seconds_left(self, _cooldown_left)
	var key_color := ApolloPalette.CREAM if is_usable() or skill == null else ApolloPalette.GREY
	PixelFont.draw_text(self, key_label, Vector2(KEY_LABEL_TOP_LEFT), key_color, ApolloPalette.OUTLINE)
	draw_set_transform(Vector2.ZERO)
	_flashes.draw_border(self, SLOT_SIZE)


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


func _icon() -> Texture2D:
	if skill == null:
		return null
	return skill.get("icon") as Texture2D


func _heat_cost() -> int:
	if skill == null:
		return 0
	var cost: Variant = skill.get("heat_cost")
	return cost if cost is int else 0
