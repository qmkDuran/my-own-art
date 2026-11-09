class_name RailBeam
extends Node2D
## A Warden Marksman's shot, drawn in code on the world's pixel grid:
##   tracking -> a dashed cyan lock-on line that follows the player (dashes crawl toward them)
##   locked   -> the line freezes and blinks white: the last moment to get out of its way
##   fired    -> a solid rail beam, white core with cyan edges, that fades out fast
## Event-only: the shot spawns it, moves it and ends it; after firing it frees itself.

## Pixels per dash and per gap, and how fast the dashes crawl, in pixels per second.
const DASH := 3
const GAP := 2
const CRAWL_SPEED := 30.0
## Seconds per blink while locked.
const BLINK_PERIOD := 0.08
## Seconds the fired beam takes to fade.
const FADE_TIME := 0.18
const LINE_COLOR := ApolloPalette.SKY
const LOCK_COLOR := ApolloPalette.WHITE
const CORE_COLOR := ApolloPalette.WHITE
const EDGE_COLOR := ApolloPalette.SKY_LIGHT

enum Phase { TRACKING, LOCKED, FIRED }

var _from: Vector2
var _to: Vector2
var _phase: Phase = Phase.TRACKING
var _age: float = 0.0
var _phase_age: float = 0.0


## Adds a tracking line to `world`.
static func spawn(world: Node) -> RailBeam:
	var beam := RailBeam.new()
	beam.z_index = 3
	world.add_child(beam)
	return beam


## Where the line runs this frame, in world coordinates.
func set_line(from: Vector2, to: Vector2) -> void:
	_from = from.round()
	_to = to.round()


func lock() -> void:
	_enter(Phase.LOCKED)


func fire() -> void:
	_enter(Phase.FIRED)


func _enter(phase: Phase) -> void:
	_phase = phase
	_phase_age = 0.0


func _process(delta: float) -> void:
	_age += delta
	_phase_age += delta
	if _phase == Phase.FIRED and _phase_age >= FADE_TIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var start := _from - global_position
	var end := _to - global_position
	var length := start.distance_to(end)
	if length < 1.0:
		return
	if _phase == Phase.FIRED:
		_draw_beam(start, end)
		return
	var color := LINE_COLOR
	if _phase == Phase.LOCKED and int(_phase_age / BLINK_PERIOD) % 2 == 0:
		color = LOCK_COLOR
	var crawl := 0 if _phase == Phase.LOCKED else int(_age * CRAWL_SPEED)
	for step in ceili(length):
		if (step - crawl) % (DASH + GAP) < DASH:
			draw_rect(Rect2(start.lerp(end, step / length).round(), Vector2.ONE), color)


func _draw_beam(start: Vector2, end: Vector2) -> void:
	var fade := 1.0 - _phase_age / FADE_TIME
	var across := (end - start).normalized().orthogonal()
	var length := start.distance_to(end)
	for step in ceili(length):
		var at := start.lerp(end, step / length)
		draw_rect(Rect2(at.round(), Vector2.ONE), Color(CORE_COLOR, fade))
		for side: float in [-1.0, 1.0]:
			draw_rect(Rect2((at + across * side).round(), Vector2.ONE), Color(EDGE_COLOR, fade))
