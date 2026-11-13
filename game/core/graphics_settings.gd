class_name GraphicsSettings
extends Node
## The graphics tier (Low, Medium, High from data/graphics.json; G cycles it): turns volumetric fog, screen-space
## reflections and ambient occlusion on or off, sets how many lamps cast shadows and the moon's shadow splits,
## caps effect lights and trails, and thins out every particle system. Particle systems remember their full
## amount, so tiers can go up again.

signal changed(tier: String)

const FULL_AMOUNT: String = "full_amount"

var tier: String = ""
var _environment: Environment
var _moon: DirectionalLight3D
var _budget: LightBudget
var _quota: VfxQuota


func setup(environment: Environment, moon: DirectionalLight3D, budget: LightBudget, quota: VfxQuota) -> void:
	name = "GraphicsSettings"
	_quota = quota
	_environment = environment
	_moon = moon
	_budget = budget
	apply(Tuning.doc("graphics")["default"])


func spec() -> Dictionary:
	return Tuning.doc("graphics")["tiers"][tier]


func density() -> float:
	return float(spec()["particle_density"])


func cycle() -> void:
	var order: Array = Tuning.doc("graphics")["order"]
	apply(order[(order.find(tier) + 1) % order.size()])


func apply(new_tier: String) -> void:
	tier = new_tier
	var settings: Dictionary = spec()
	_environment.volumetric_fog_enabled = settings["volumetric_fog"]
	_environment.ssr_enabled = settings["ssr"]
	_environment.ssao_enabled = settings["ssao"]
	_budget.allowed = int(settings["shadowed_lights"])
	_quota.apply_tier(settings)
	_budget.refresh()
	var splits: int = int(settings["moon_splits"])
	_moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if splits == 4 else \
		DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	thin_particles(get_tree().current_scene if is_inside_tree() else null)
	changed.emit(tier)


## Scales every particle system under a node to this tier's density (new systems call it too).
func thin_particles(root: Node) -> void:
	if root == null:
		return
	for node: Node in root.find_children("*", "GPUParticles3D", true, false):
		var particles: GPUParticles3D = node
		if not particles.has_meta(FULL_AMOUNT):
			particles.set_meta(FULL_AMOUNT, particles.amount)
		particles.amount = maxi(1, int(int(particles.get_meta(FULL_AMOUNT)) * density()))
