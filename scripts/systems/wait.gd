class_name Wait
extends RefCounted
## Pauses in a node's own coroutines: `await Wait.seconds(self, 0.5)`.
##
## Why not `await get_tree().create_timer(...).timeout`: a tree timer outlives the node, so
## when the node is freed meanwhile (its zone was unloaded, the game restarted) the rest of
## the function resumes on a node that is gone, an engine error, and anything it meant to
## undo (e.g. a slow-motion time scale) stays done. This wait belongs to the node instead
## (a Tween bound to it): if the node is freed first, the rest of the function simply never
## runs. Like a tree timer it keeps counting while the game is paused.


## Fires after `duration` seconds of game time (or real time, with `ignore_time_scale`).
static func seconds(node: Node, duration: float, ignore_time_scale: bool = false) -> Signal:
	var tween := node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(ignore_time_scale)
	tween.tween_interval(duration)
	return tween.finished
