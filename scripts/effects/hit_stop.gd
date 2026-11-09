class_name HitStop
extends RefCounted
## Freezes the game for a blink on a finisher, so the hit lands with weight: time slows
## almost to a stop for `REAL_SECONDS` of real time, then runs on.

const REAL_SECONDS := 0.09
const FROZEN_TIME_SCALE := 0.05


static func play(tree: SceneTree) -> void:
	Engine.time_scale = FROZEN_TIME_SCALE
	await tree.create_timer(REAL_SECONDS, true, false, true).timeout
	Engine.time_scale = 1.0
