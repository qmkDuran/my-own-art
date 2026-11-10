class_name DemoRecorder
extends RefCounted
## Scripted walks for recordings, driven by data:
## {"start": [x, y], "face": "up", "pause": s, "waypoints": [[x, y, pause], ...],
##  "events": [[seconds, "method"], ...], "quit_after": s}
## Events call methods on the scene by name; the quit timer is bound to the SceneTree so it survives scene changes.


static func run(scene: Node, player: Player, demo: Dictionary) -> void:
	if demo.has("start"):
		player.position = SceneData.vec(demo["start"])
	if demo.has("face"):
		player.face(demo["face"])
	player.autopilot = SceneData.waypoints(demo.get("waypoints", []))
	player.autopilot_pause = float(demo.get("pause", 0.0))
	var tree: SceneTree = scene.get_tree()
	for ev: Array in demo.get("events", []):
		tree.create_timer(float(ev[0])).timeout.connect(Callable(scene, String(ev[1])))
	if demo.has("quit_after"):
		tree.create_timer(float(demo["quit_after"])).timeout.connect(tree.quit)
