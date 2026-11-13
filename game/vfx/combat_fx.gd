class_name CombatFx
extends Node3D
## The fight's short-lived effects, built from data/vfx.json "combat": the impacts of the Lamplighter's magic
## (layered: a star pop, a light, a ring, embers, smoke and a scorch), enemy spawn puffs and defeat pops, enemy
## shots popping, telegraphed attacks landing (violet flame), the elite's shield shattering, the boss's phase
## flare and damage numbers. Everything lives in the world (not on whoever made it) and frees itself.

const LINE_LIFT: float = 0.1
const BREAK_RISE: float = 1.2
const BREAK_SECONDS: float = 1.0
const BREAK_FONT: int = 96
const BREAK_PIXEL: float = 0.006
const FLAME_RISE: float = 2.5
const BREAK_STOP_FRAMES: int = 5
const PUFF_RING: float = 4.0
const FLAME_LIFE: float = 0.25
const FLAME_SPREAD: float = 0.8
const FLAME_CONE: float = 0.15
const FLAME_RING: float = 0.2
const FLAME_LIGHT_REACH: float = 2.5
const FLAME_LIGHT_FADE: float = 0.15
const BREAK_POP: float = 0.3
const BREAK_FLASH: float = 0.4
const RING_FROM: float = 0.2

var kit: VfxKit


func setup(effects_kit: VfxKit) -> void:
	name = "CombatFx"
	kit = effects_kit


func look(key: String) -> Dictionary:
	return Tuning.doc("vfx")["combat"][key]


## A layered impact (spec from data/vfx.json combat.<key>: "impact" and "mark") at a point over the ground.
func impact(key: String, at: Vector3, ground: Vector3) -> void:
	var spec: Dictionary = look(key)
	var burst := ImpactBurst.new()
	kit.place(burst, at)
	burst.play(kit, spec["impact"], spec["mark"], ground)


## The same layers with explicit specs (the super's motes and final burst).
func impact_with(impact_spec: Dictionary, mark_spec: Dictionary, at: Vector3, ground: Vector3) -> void:
	var burst := ImpactBurst.new()
	kit.place(burst, at)
	burst.play(kit, impact_spec, mark_spec, ground)


func damage_number(at: Vector3, amount: float, critical: bool, on_shield: bool) -> void:
	DamageNumber.pop_up(get_tree().current_scene, at, amount, critical, on_shield)


func spawn_puff(enemy: Enemy) -> void:
	var spec: Dictionary = look("enemy")
	var puff: GPUParticles3D = ParticleBursts.smoke(kit.quota.count(int(spec["puff_count"])), Tuning.color(
		spec["puff"]), float(spec["puff_size"]), float(spec["puff_lifetime"]))
	kit.place(puff, enemy.global_position)
	_ring(enemy.global_position, Tuning.color(spec["charge"]), enemy.radius * PUFF_RING, float(spec["puff_lifetime"]))
	kit.sfx.cue("spawn", enemy.global_position)


func defeat_pop(enemy: Enemy) -> void:
	var spec: Dictionary = look("enemy")
	var sparkle := SparkleBurst.new()
	kit.place(sparkle, enemy.centre())
	var star := StarPop.new()
	kit.place(star, enemy.centre())
	star.play(Tuning.color(spec["pop"]), Tuning.color(look("primary")["impact"]["tip_color"]), enemy.radius * 2.0,
		float(spec["pop_lifetime"]), float(look("primary")["impact"]["pop_energy"]))


func shot_pop(at: Vector3, size_share: float = 1.0) -> void:
	var spec: Dictionary = look("enemy")
	var colour: Color = Tuning.color(spec["shot"])
	kit.place(ParticleBursts.embers(kit.quota.count(int(spec["pop_count"])), colour, float(spec["pop_size"]),
		float(spec["pop_speed"]), float(spec["pop_lifetime"])), at)
	var star := StarPop.new()
	kit.place(star, at)
	star.play(colour, colour.darkened(0.5), float(spec["shot_size"]) * size_share, float(spec["pop_lifetime"]) * 0.5,
		1.0)


## A telegraphed attack lands: violet flame bursts over its area (along a line, a row of them).
func telegraph_lands(telegraph: Telegraph) -> void:
	var spec: Dictionary = look("telegraph")
	if telegraph.shape == "circle":
		_flame(telegraph.global_position, telegraph.radius, spec)
		return
	var step: float = float(spec["line_step"])
	var count: int = maxi(1, int(telegraph.length / step))
	for index: int in count:
		var at: Vector3 = telegraph.global_position - telegraph.global_basis.z * (index + 0.5) * step
		get_tree().create_timer(index * Hit.LINE_DELAY, false).timeout.connect(_flame.bind(at + Vector3.UP *
			LINE_LIFT, telegraph.width * 0.5, spec))


func _flame(at: Vector3, radius: float, spec: Dictionary) -> void:
	var colour: Color = Tuning.color(spec["burst"])
	var embers: GPUParticles3D = ParticleBursts.embers(kit.quota.count(int(spec["burst_embers"])), colour, float(
		spec["burst_size"]), float(spec["burst_speed"]), FLAME_RISE * FLAME_LIFE)
	var process: ParticleProcessMaterial = embers.process_material
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = radius * FLAME_SPREAD
	process.direction = Vector3.UP
	process.spread = ParticleBursts.ALL_DIRECTIONS_DEG * FLAME_CONE
	process.gravity = Vector3.UP * FLAME_RISE
	kit.place(embers, at)
	_ring(at, colour, radius * 2.0, FLAME_RISE * FLAME_RING)
	var light: EffectLight = EffectLight.make(kit.quota, colour, float(spec["burst_light"]), radius * FLAME_LIGHT_REACH)
	if light != null:
		kit.place(light, at + Vector3.UP)
		light.fade_out(FLAME_RISE * FLAME_LIGHT_FADE)


func shield_shatter(enemy: Enemy) -> void:
	var spec: Dictionary = look("shield")
	var at: Vector3 = enemy.centre()
	var colour: Color = Tuning.color(spec["edge"])
	kit.place(ParticleBursts.embers(kit.quota.count(int(spec["shards"])), colour, float(spec["shard_size"]),
		float(spec["shard_speed"]), float(spec["shard_lifetime"])), at)
	var star := StarPop.new()
	kit.place(star, at)
	star.play(colour, Tuning.color(spec["color"]), float(spec["pop_size"]), BREAK_SECONDS * BREAK_POP, 1.0)
	_ring(enemy.global_position, colour, float(spec["pop_size"]) * 2.0, BREAK_SECONDS * 0.5)
	var light: EffectLight = EffectLight.make(kit.quota, colour, float(spec["flash_energy"]),
		float(spec["flash_range"]))
	if light != null:
		kit.place(light, at)
		light.fade_out(BREAK_SECONDS * BREAK_FLASH)
	_label(at, String(spec["break_label"]), colour)
	kit.sfx.cue("shield_break", at)
	kit.hit_feel.hit_stop(BREAK_STOP_FRAMES, Hit.STOP_SCALE)


func phase_ring(enemy: Enemy) -> void:
	var spec: Dictionary = look("enemy")
	var colour: Color = Tuning.color(spec["phase_ring"])
	_ring(enemy.global_position, colour, float(spec["phase_ring_size"]), BREAK_SECONDS)
	kit.place(ParticleBursts.embers(kit.quota.count(int(look("telegraph")["burst_embers"]) * 3), colour, float(
		look("telegraph")["burst_size"]) * 2.0, float(look("telegraph")["burst_speed"]) * 2.0, BREAK_SECONDS),
		enemy.centre())


## A flat glowing ring on the ground that swells and fades.
func _ring(at: Vector3, colour: Color, size: float, seconds: float) -> void:
	var ring: MeshInstance3D = RingMesh.make(colour)
	kit.place(ring, at + Vector3.UP * RingMesh.LIFT)
	ring.scale = Vector3(size * RING_FROM, RingMesh.LIFT, size * RING_FROM)
	var tween: Tween = ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3(size * 0.5, RingMesh.LIFT, size * 0.5), seconds).set_ease(
		Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(ring, "transparency", 1.0, seconds)
	tween.chain().tween_callback(ring.queue_free)


func _label(at: Vector3, text: String, colour: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = BREAK_FONT
	label.pixel_size = BREAK_PIXEL
	label.modulate = colour
	label.outline_size = BREAK_FONT / 6
	label.outline_modulate = Tuning.color(look("damage")["outline"])
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	kit.place(label, at + Vector3.UP * 0.5)
	var tween: Tween = label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y + BREAK_RISE, BREAK_SECONDS)
	tween.tween_property(label, "modulate:a", 0.0, BREAK_SECONDS * 0.5).set_delay(BREAK_SECONDS * 0.5)
	tween.chain().tween_callback(label.queue_free)
