extends Node
## --perf: after the zone settles, prints frame rate, draw calls, objects drawn and node count (software GL under
## xvfb cannot judge a real GPU's speed; the counts are what to compare between builds).

const SETTLE: float = 3.0
const SAMPLE: float = 2.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	while Game.current == null:
		await get_tree().process_frame
	await get_tree().create_timer(SETTLE).timeout
	var frames: int = Engine.get_frames_drawn()
	await get_tree().create_timer(SAMPLE).timeout
	print("PERF %s fps %.1f draw calls %d objects %d nodes %d" % [Game.current.zone_id, (Engine.get_frames_drawn() - frames) / SAMPLE,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	get_tree().quit()
