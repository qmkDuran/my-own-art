extends Node
## --perf (needs a real renderer: xvfb + Vulkan): the busiest fight (the Gloom King in phase two in his ring with
## his ghosts, a swarm, shooters and the elite, in the rain, with the primary streaming, the ward up, a bomb
## bursting and the Sunrise burning overhead) measured on proxies for each graphics tier: draw calls, objects and
## primitives drawn, lights in view, shadow-casting lights, nodes and particles, against data/perf.json, with the
## default 60 fps cap on. Frame times are printed for reference only: on a CPU rasteriser they say nothing about a
## real GPU.

const SETTLE_SECONDS: float = 1.5
const MILLION: float = 1000000.0
const FIGHT: Dictionary = { "mushroom_imp": 8, "pumpkin_head": 3, "lantern_moth": 4, "scarecrow_knight": 1 }
const SPREAD: float = 9.0

var m: Main
var failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	m = Main.current
	if Engine.max_fps != int(Tuning.doc("graphics")["display"]["default_frame_cap"]):
		failures.append("the 60 fps cap is not on (max_fps %d)" % Engine.max_fps)
	await _fight()
	var results: Array[Dictionary] = []
	for tier: String in Tuning.doc("graphics")["order"]:
		m.graphics.apply(tier)
		await _keep_busy(SETTLE_SECONDS)
		results.append(_measure())
		print("PERF %s: %s" % [tier, results[-1]])
	_check(results)
	for failure: String in failures:
		print("PERF FAIL ", failure)
	if failures.is_empty():
		print("PERF PASS")
	get_tree().quit(0 if failures.is_empty() else 1)


func _fight() -> void:
	m.controller.enabled = false
	m.kit_input.enabled = false
	m.health.invulnerable = true
	m.weather.set_raining(true)
	m.weather.settle()
	var centre: Vector3 = Tuning.point(Tuning.doc("mission")["arena"]["center"])
	m.player.global_position = centre + Vector3(-8.0, 0.0, 0.0)
	m.camera_rig.yaw = -PI * 0.5
	m.camera_rig.snap()
	var boss: Enemy = m.roster.spawn("gloom_king", centre + Vector3(4.0, 0.0, 0.0))
	await get_tree().create_timer(1.0).timeout
	boss.take_hit(Hit.new(boss.max_health * 0.55, "heavy", boss.centre()))
	for kind: String in FIGHT:
		for index: int in int(FIGHT[kind]):
			m.roster.spawn(kind, centre + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * SPREAD)
	m.kit.aim.lock(boss)
	await get_tree().create_timer(2.0).timeout
	m.kit.meter.add(SuperMeter.cost())
	m.kit.sunrise.fire()
	m.kit.ward.raise()
	m.kit.bomb.begin_aim()
	await get_tree().create_timer(0.2).timeout
	m.kit.bomb.release()


func _keep_busy(seconds: float) -> void:
	var left: float = seconds
	while left > 0.0:
		m.kit.primary.trigger()
		await get_tree().process_frame
		left -= get_process_delta_time()


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
		"enemies": m.roster.enemies.size(), "fps_reference_only": Engine.get_frames_per_second() }


func _check(results: Array[Dictionary]) -> void:
	var budgets: Dictionary = Tuning.doc("perf")["budgets"]
	for key: String in budgets:
		if float(results[-1][key]) > float(budgets[key]):
			failures.append("high tier: %s %.1f over the budget %.1f" % [key, float(results[-1][key]),
				float(budgets[key])])
	for index: int in results.size() - 1:
		for key: String in ["shadowed_lights", "particles"]:
			if float(results[index][key]) > float(results[index + 1][key]):
				failures.append("tier %d draws more %s than the tier above" % [index, key])
