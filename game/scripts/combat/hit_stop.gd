class_name HitStop
extends RefCounted
## A brief freeze on heavy hits and kills (game feel). Overlapping stops are counted; time resumes when the last
## one ends. Real-time timers, so the stop lasts the same however slow time runs.

const SLOW: float = 0.06

static var _pending: int = 0


static func trigger(tree: SceneTree, seconds: float) -> void:
	_pending += 1
	Engine.time_scale = SLOW
	tree.create_timer(seconds, true, false, true).timeout.connect(_release)


static func _release() -> void:
	_pending = maxi(0, _pending - 1)
	if _pending == 0:
		Engine.time_scale = 1.0
