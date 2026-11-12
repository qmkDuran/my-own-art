class_name HitStop
extends RefCounted
## A brief freeze on heavy hits and kills (game feel). Overlapping stops are counted; time resumes when the last
## one ends. Real-time timers, so the stop lasts the same however slow time runs.

const SLOW: float = 0.06

static var _pending: int = 0
static var base: float = 1.0            ## the speed time returns to (the tamer prototype's slow-time lowers it)


static func trigger(tree: SceneTree, seconds: float) -> void:
	_pending += 1
	Engine.time_scale = SLOW * base
	tree.create_timer(seconds, true, false, true).timeout.connect(_release)


## Changes the resting speed of time (1 normal); a hit-stop in progress keeps its freeze.
static func set_base(scale: float) -> void:
	base = scale
	if _pending == 0:
		Engine.time_scale = base


static func _release() -> void:
	_pending = maxi(0, _pending - 1)
	if _pending == 0:
		Engine.time_scale = base
