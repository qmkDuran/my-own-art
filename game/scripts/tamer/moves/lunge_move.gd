class_name LungeMove
extends MoveKind
## A dash to the aim (or a blink, for tricksters): foes along the way (path_hits) or around the landing are hit.

const BLINK_RADIUS: float = 40.0


func cast(user: Creature, m: Dictionary, at: Vector2, _strength: float = 1.0) -> void:
	var from: Vector2 = user.global_position
	var to: Vector2 = TamerGame.current.layout.free_spot_near(clamp_aim(user, m, at), user.hit_radius())
	var el: String = element(user, m)
	var time: float = float(m.get("time", 0.2))
	if bool(m.get("blink", false)):
		Fx.burst(TamerGame.current.fx_layer, from + Vector2(0, -8), 18, Vector2(40, 160), 0.4, TamerData.sparks(el))
		user.global_position = to
		user.busy_t = time
		_land(user, m, from, to)
		return
	user.dash((to - from) / time, time)
	Audio.sfx("leap", -8.0, randf_range(1.0, 1.2))
	user.get_tree().create_timer(time, false).timeout.connect(func() -> void:
		if is_instance_valid(user) and user.alive():
			_land(user, m, from, user.global_position))


func _land(user: Creature, m: Dictionary, from: Vector2, to: Vector2) -> void:
	var el: String = element(user, m)
	TamerFx.streak(from, to, el)
	TamerFx.blast(to, float(m.get("radius", BLINK_RADIUS)), el)
	TerrainRules.on_impact(to, float(m.get("radius", BLINK_RADIUS)), m, float(m["damage"]))
	Audio.sfx("slam", -8.0, randf_range(1.1, 1.3))
	var hit: Array[Combatant] = foes_in(user, to, float(m.get("radius", BLINK_RADIUS)))
	if bool(m.get("path_hits", false)):
		for f: Combatant in user.foes():
			var near: Vector2 = Geometry2D.get_closest_point_to_segment(f.global_position, from, to)
			if near.distance_to(f.global_position) <= float(m["radius"]) + f.hit_radius() and not hit.has(f):
				hit.append(f)
	for f: Combatant in hit:
		CreatureCombat.hit(user, f, m, (f.global_position - from).normalized())
