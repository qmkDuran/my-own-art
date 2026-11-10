class_name HitStop
extends RefCounted
## Briefly slows the whole game on impact so hits feel heavy.

const SLOW_SCALE := 0.05

static var _active := 0


static func apply(tree: SceneTree, duration: float) -> void:
	_active += 1
	Engine.time_scale = SLOW_SCALE
	await tree.create_timer(duration, true, false, true).timeout
	_active -= 1
	if _active <= 0:
		_active = 0
		Engine.time_scale = 1.0


static func reset() -> void:
	_active = 0
	Engine.time_scale = 1.0
