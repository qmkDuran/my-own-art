class_name SmokeGraphics
extends RefCounted
## Graphics tier checks for the smoke test (headless, so on proxies, not frame times): each tier must be no heavier
## than the next on every proxy (screen effects on, lamps casting shadows, live particles) and lighter overall.

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	var costs: Array[Dictionary] = []
	for tier: String in Tuning.doc("graphics")["order"]:
		m.graphics.apply(tier)
		costs.append(_cost())
		print("SMOKE graphics %s: %s" % [tier, costs[-1]])
	for index: int in costs.size() - 1:
		var lighter: Dictionary = costs[index]
		var heavier: Dictionary = costs[index + 1]
		for key: String in lighter:
			if int(lighter[key]) > int(heavier[key]):
				failures.append("graphics: %s is heavier on %s than the next tier" % [index, key])
		if lighter.values() == heavier.values():
			failures.append("graphics: tier %d is no lighter than the next" % index)
	m.graphics.apply(Tuning.doc("graphics")["default"])
	return failures


func _cost() -> Dictionary:
	var environment: Environment = m.environment_node.environment
	var particles: int = 0
	for node: Node in m.find_children("*", "GPUParticles3D", true, false):
		particles += (node as GPUParticles3D).amount
	return { "screen_effects": int(environment.volumetric_fog_enabled) + int(environment.ssr_enabled) +
		int(environment.ssao_enabled), "shadowed_lights": m.budget.allowed, "particles": particles,
		"moon_splits": m.moon.directional_shadow_mode }
