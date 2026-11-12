class_name BurstMove
extends MoveKind
## An area: at the user ("self", it follows them for pulses) or at the aim, after a warning circle in the element's
## colour (so wild creatures' big moves can be dodged), in one or several pulses. Seed bursts also heal the user.

const WARN_ALPHA: float = 0.9


func cast(user: Creature, m: Dictionary, at: Vector2) -> void:
	var fixed: Vector2 = clamp_aim(user, m, at)
	var delay: float = float(m.get("delay", 0.0))
	if delay <= 0.0:
		_pulses(user, m, fixed)
		return
	var center: Vector2 = user.global_position if String(m.get("at", "aim")) == "self" else fixed
	var t := Telegraph.circle(TamerGame.current.fx_layer, center, float(m["radius"]), delay)
	t.col = TamerData.color(element(user, m), "core", WARN_ALPHA)
	t.fired.connect(func() -> void:
		if is_instance_valid(user) and user.alive():
			_pulses(user, m, fixed))


func _pulses(user: Creature, m: Dictionary, fixed: Vector2) -> void:
	var n: int = int(m.get("pulses", 1))
	for k: int in n:
		if k == 0:
			_pulse(user, m, fixed)
			continue
		user.get_tree().create_timer(float(m["every"]) * k, false).timeout.connect(func() -> void:
			if is_instance_valid(user) and user.alive():
				_pulse(user, m, fixed))


func _pulse(user: Creature, m: Dictionary, fixed: Vector2) -> void:
	var center: Vector2 = user.global_position if String(m.get("at", "aim")) == "self" else fixed
	var el: String = element(user, m)
	TamerFx.blast(center, float(m["radius"]), el, bool(m.get("bond", false)))
	Audio.sfx("flare", -10.0, randf_range(1.1, 1.4))
	for f: Combatant in foes_in(user, center, float(m["radius"])):
		CreatureCombat.hit(user, f, m, (f.global_position - center).normalized())
	if m.has("heal"):
		user.rec.heal_points(float(m["heal"]))
