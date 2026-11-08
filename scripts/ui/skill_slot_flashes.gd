class_name SkillSlotFlashes
extends RefCounted
## The short flashes a SkillSlot plays, and the coloured border they draw around it:
## - used: white → gold → orange, in step with the trainer's shout;
## - refused (still recovering): a short, dim grey edge;
## - ready (the skill just became usable): gold → orange, with a ring just outside the slot.

## Border colour for each step of the "used" flash (one step per shout stage).
const USED_FLASH_COLORS: Array[Color] = [ApolloPalette.WHITE, ApolloPalette.GOLD, ApolloPalette.ORANGE_DARK]
const REFUSED_FLASH_SECONDS := 0.25
## The "ready" glow: how long it lasts, and its colours from start to end.
const READY_GLOW_SECONDS := 0.4
const READY_GLOW_COLORS: Array[Color] = [ApolloPalette.GOLD, ApolloPalette.ORANGE, ApolloPalette.ORANGE_DARK]
## How far outside the slot's own outline the "ready" ring sits, in pixels.
const READY_RING_MARGIN := 2

var _used_time: float = -1.0
var _refused_left: float = 0.0
var _ready_time: float = -1.0


func start_used() -> void:
	_used_time = 0.0
	_ready_time = -1.0


func start_refused() -> void:
	_refused_left = REFUSED_FLASH_SECONDS


func start_ready() -> void:
	_ready_time = 0.0


## Moves every running flash on. Returns true while any is running (the slot must redraw).
func advance(delta: float) -> bool:
	var is_running := false
	if _used_time >= 0.0:
		_used_time += delta
		if used_stage() >= USED_FLASH_COLORS.size():
			_used_time = -1.0
		is_running = true
	if _refused_left > 0.0:
		_refused_left = maxf(0.0, _refused_left - delta)
		is_running = true
	if _ready_time >= 0.0:
		_ready_time += delta
		if _ready_time >= READY_GLOW_SECONDS:
			_ready_time = -1.0
		is_running = true
	return is_running


## Which step of the "used" flash is showing (0, 1, 2), or -1 when none is.
func used_stage() -> int:
	if _used_time < 0.0:
		return -1
	return int(_used_time / HudTrainer.SHOUT_STAGE_SECONDS)


## Which colour of the "ready" glow is showing (0 = brightest), or -1 when none is.
func ready_stage() -> int:
	if _ready_time < 0.0:
		return -1
	var share := _ready_time / READY_GLOW_SECONDS
	return mini(int(share * READY_GLOW_COLORS.size()), READY_GLOW_COLORS.size() - 1)


func ready_color() -> Color:
	return READY_GLOW_COLORS[maxi(0, ready_stage())]


## The frame's outer edge in the flash colour while a flash shows; during the "ready" glow
## also a ring one pixel outside the slot's outline.
func draw_border(canvas: CanvasItem, slot_size: int) -> void:
	var color: Color
	var stage := used_stage()
	if stage >= 0 and stage < USED_FLASH_COLORS.size():
		color = USED_FLASH_COLORS[stage]
	elif ready_stage() >= 0:
		color = ready_color()
		var ring_side := slot_size + READY_RING_MARGIN * 2
		_draw_ring(canvas, Rect2(-READY_RING_MARGIN, -READY_RING_MARGIN, ring_side, ring_side), color)
	elif _refused_left > 0.0:
		color = ApolloPalette.GREY
	else:
		return
	_draw_ring(canvas, Rect2(0, 0, slot_size, slot_size), color)


## A one-pixel line along the inside of `box`.
static func _draw_ring(canvas: CanvasItem, box: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(box.position.x, box.position.y, box.size.x, 1), color)
	canvas.draw_rect(Rect2(box.position.x, box.end.y - 1, box.size.x, 1), color)
	canvas.draw_rect(Rect2(box.position.x, box.position.y, 1, box.size.y), color)
	canvas.draw_rect(Rect2(box.end.x - 1, box.position.y, 1, box.size.y), color)
