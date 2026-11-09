class_name PortraitShoutTicks
extends RefCounted
## The trainer's shout as three short tick lines popping from above the portrait's mouth side:
## up-left, straight up and up-right, flying outward white, then gold, then orange.

## How long each step of the shout lasts (the skill slot's flash keeps the same beat).
const STAGE_SECONDS := 0.0875
## The three ticks, as [start relative to the anchor, direction].
const TICKS := [
	[Vector2i(-3, 0), Vector2i(-1, -1)],
	[Vector2i(0, -1), Vector2i(0, -1)],
	[Vector2i(3, 0), Vector2i(1, -1)],
]
## Each step of the shout: how far out the ticks start, how long they are, and their colour.
const STAGES := [
	{"distance": 0, "length": 2, "color": ApolloPalette.WHITE},
	{"distance": 1, "length": 3, "color": ApolloPalette.WHITE},
	{"distance": 3, "length": 2, "color": ApolloPalette.GOLD},
	{"distance": 5, "length": 1, "color": ApolloPalette.ORANGE_DARK},
]

## Seconds into the shout, or -1 when not shouting.
var _time: float = -1.0


func start() -> void:
	_time = 0.0


## Moves the shout on. Returns true while it runs (the portrait must redraw).
func advance(delta: float) -> bool:
	if _time < 0.0:
		return false
	_time += delta
	if _stage() >= STAGES.size():
		_time = -1.0
	return true


func draw(canvas: CanvasItem, anchor: Vector2i) -> void:
	if _time < 0.0:
		return
	var step: Dictionary = STAGES[_stage()]
	for tick: Array in TICKS:
		var start: Vector2i = anchor + (tick[0] as Vector2i)
		var direction: Vector2i = tick[1]
		for distance in range(step["distance"], step["distance"] + step["length"]):
			PixelShape.draw_pixel(canvas, Vector2(start + direction * distance), step["color"])


func _stage() -> int:
	return int(_time / STAGE_SECONDS)
