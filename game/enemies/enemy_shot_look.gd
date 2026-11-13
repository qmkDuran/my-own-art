class_name EnemyShotLook
## The look of an enemy shot: a soft violet orb with a faint ribbon trail and a small moving light (if the tier
## has one to spare). When the shot ends, the trail is left behind to fade.

const LINGER: float = 0.4


static func make(fx: CombatFx, shot: Node3D) -> Node3D:
	var look: Dictionary = Tuning.doc("vfx")["combat"]["enemy"]
	var colour: Color = Tuning.color(look["shot"])
	var orb: Node3D = SoftGlow.make(colour, float(look["shot_size"]), float(look["shot_energy"]))
	shot.add_child(orb)
	var light: EffectLight = EffectLight.make(fx.kit.quota, colour, float(look["shot_light"]), float(
		look["shot_light_range"]))
	if light != null:
		shot.add_child(light)
	if not fx.kit.quota.trails:
		return null
	var trail := RibbonTrail.new()
	trail.setup(shot, colour, float(look["shot_trail"]), Tuning.i("vfx_trail", "points"))
	shot.add_child(trail)
	return trail


static func leave(trail: Node3D) -> void:
	if trail == null or not is_instance_valid(trail):
		return
	trail.reparent(trail.get_tree().current_scene)
	trail.get_tree().create_timer(LINGER, false).timeout.connect(trail.queue_free)
