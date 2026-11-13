extends Node
## --perf (needs a real renderer: xvfb + Vulkan): the busiest scene (the square in the rain, a big creature wave,
## every lamp lit, the player's magic going) measured on proxies for each graphics tier: draw calls, objects and
## primitives drawn, lights in view, shadow-casting lights, nodes and particles, against data/perf.json. Frame times
## are printed for reference only: on a CPU rasteriser they say nothing about a real GPU.

const SETTLE_SECONDS: float = 2.0
const RING_MIN: float = 4.0
const RING_SPREAD: float = 12.0
const MILLION: float = 1000000.0

var m: Main
var failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	m = Main.current
	m.controller.enabled = false
	m.player.global_position = Vector3(0, 0.05, 6)
	m.weather.set_raining(true)
	m.weather.settle()
	m.start_night()
	m.night.set_physics_process(false)
	for id: String in ["firefly_swarm", "candle_ring", "moonbeam", "bell_chime"]:
		m.night.loadout.apply({ "kind": "attacks", "id": id })
	_wave()
	var results: Array[Dictionary] = []
	for tier: String in Tuning.doc("graphics")["order"]:
		m.graphics.apply(tier)
		await get_tree().create_timer(SETTLE_SECONDS).timeout
		results.append(_measure())
		print("PERF %s: %s" % [tier, results[-1]])
	_check(results)
	for failure: String in failures:
		print("PERF FAIL ", failure)
	if failures.is_empty():
		print("PERF PASS")
	get_tree().quit(0 if failures.is_empty() else 1)


func _wave() -> void:
	var kinds: Array[String] = ["sheet_ghost", "pumpkin_head", "lantern_moth"]
	var count: int = int(Tuning.doc("perf")["wave"])
	for index: int in count:
		var angle: float = TAU * index / count
		var at: Vector3 = m.player.global_position + Vector3(cos(angle), 0, sin(angle)) * (RING_MIN + randf() *
			RING_SPREAD)
		var creature: Creature = m.night.horde.spawn(kinds[index % kinds.size()], at)
		creature.set_physics_process(false)


func _measure() -> Dictionary:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var lights: int = 0
	var shadowed: int = 0
	for node: Node in m.find_children("*", "Light3D", true, false):
		var light: Light3D = node
		if light is DirectionalLight3D or not light.is_visible_in_tree():
			continue
		if camera.is_position_in_frustum(light.global_position):
			lights += 1
		shadowed += int(light.shadow_enabled)
	var particles: int = 0
	for node: Node in m.find_children("*", "GPUParticles3D", true, false):
		particles += (node as GPUParticles3D).amount
	return { "draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"primitives_millions": RenderingServer.get_rendering_info(
			RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / MILLION,
		"lights_in_view": lights, "shadowed_lights": shadowed,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "particles": particles,
		"fps_reference_only": Engine.get_frames_per_second() }


func _check(results: Array[Dictionary]) -> void:
	var budgets: Dictionary = Tuning.doc("perf")["budgets"]
	for key: String in budgets:
		if float(results[-1][key]) > float(budgets[key]):
			failures.append("high tier: %s %.1f over the budget %.1f" % [key, float(results[-1][key]),
				float(budgets[key])])
	for index: int in results.size() - 1:
		for key: String in ["draw_calls", "shadowed_lights", "particles"]:
			if float(results[index][key]) > float(results[index + 1][key]):
				failures.append("tier %d draws more %s than the tier above" % [index, key])
