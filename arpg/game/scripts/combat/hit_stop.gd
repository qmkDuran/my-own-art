class_name HitStop
extends RefCounted
## A brief freeze on solid hits (game-feel): time slows for a few hundredths of a second, then resumes.
## Overlapping stops are counted, so time resumes only when the last one ends.

const SLOW: float = 0.05

static var _pending: int = 0


static func trigger(tree: SceneTree, seconds: float) -> void:
	_pending += 1
	Engine.time_scale = SLOW
	tree.create_timer(seconds, true, false, true).timeout.connect(_release)


static func _release() -> void:
	_pending = maxi(0, _pending - 1)
	if _pending == 0:
		Engine.time_scale = 1.0
