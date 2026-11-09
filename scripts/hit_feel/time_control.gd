class_name TimeControl
extends Node
## The one owner of `Engine.time_scale`, so hit-stops and slow-mo never fight: a hit-stop
## (near-freeze) wins over a slow-mo, which wins over normal speed. Counted in real frames
## (unscaled time), so a freeze lasts the same however slow the game is running.
##
## Lives once under the tree root, made on first use: `TimeControl.of(tree)`.

const NODE_NAME := "TimeControl"
## One frame at 60 fps, in seconds.
const FRAME_SECONDS := 1.0 / 60.0
## How slow a hit-stop runs the game (almost frozen, but never 0 so timers still move).
const HIT_STOP_SCALE := 0.05
## Guards the real-time sum against a time scale of zero.
const MIN_TIME_SCALE := 0.001

## The one instance (it is added to the tree a moment after it is made).
static var _instance: TimeControl

var _stop_seconds_left: float = 0.0
var _slow_seconds_left: float = 0.0
var _slow_scale: float = 1.0


static func of(tree: SceneTree) -> TimeControl:
	if is_instance_valid(_instance):
		return _instance
	var made := TimeControl.new()
	_instance = made
	made.name = NODE_NAME
	made.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child.call_deferred(made)
	return made


## Freezes the game for `frames` real frames (a longer freeze replaces a shorter one).
func hit_stop(frames: int) -> void:
	_stop_seconds_left = maxf(_stop_seconds_left, frames * FRAME_SECONDS)
	_apply()


## Runs the game at `time_scale` for `game_frames` frames of game time.
func slow_mo(time_scale: float, game_frames: int) -> void:
	_slow_scale = time_scale
	_slow_seconds_left = maxf(_slow_seconds_left, game_frames * FRAME_SECONDS / time_scale)
	_apply()


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, MIN_TIME_SCALE)
	_stop_seconds_left = maxf(0.0, _stop_seconds_left - real_delta)
	_slow_seconds_left = maxf(0.0, _slow_seconds_left - real_delta)
	_apply()


func _apply() -> void:
	if _stop_seconds_left > 0.0:
		Engine.time_scale = HIT_STOP_SCALE
	elif _slow_seconds_left > 0.0:
		Engine.time_scale = _slow_scale
	else:
		Engine.time_scale = 1.0
