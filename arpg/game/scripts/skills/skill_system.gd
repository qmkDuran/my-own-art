class_name SkillSystem
extends Node
## Michael's skills (data: res://data/skills.json): cooldowns, glory cost, ranks and modifiers, unique-item effects
## ("procs"), and every skill's effect. Damage hits enemies in the "demons" group only: Michael never fights people
## (Eph 6:12).

signal used(skill: String)
signal hit_landed(count: int)

const GOLD := Color("f9c22b")
const PALE := Color("fbff86")
const SKY := Color("8fd3ff")

var m: Michael
var cooldowns: Dictionary = {}
var radiance_on: bool = false
var _shield_t: float = 0.0
var _charge_t: float = 0.0
var _charge_to: Vector2
var _radiance_tick: float = 0.0
var _shield_fx: Node2D
var _radiance_fx: PointLight2D


func _init(michael: Michael) -> void:
	m = michael


func _ready() -> void:
	_shield_fx = Node2D.new()
	_shield_fx.visible = false
	_shield_fx.z_index = 7
	_shield_fx.light_mask = 0
	_shield_fx.material = SpriteFactory.additive()
	_shield_fx.draw.connect(_draw_shield)
	m.add_child.call_deferred(_shield_fx)
	_radiance_fx = PointLight2D.new()
	_radiance_fx.texture = LightTex.radial(256)
	_radiance_fx.color = Color(1.0, 0.85, 0.45)
	_radiance_fx.energy = 0.0
	_radiance_fx.position = Vector2(0, -10)
	m.add_child.call_deferred(_radiance_fx)


func data(id: String) -> Dictionary:
	return GameData.skill(id)


func learned(id: String) -> bool:
	return m.prog.rank(id) > 0


func remaining(id: String) -> float:
	return maxf(0.0, float(cooldowns.get(id, 0.0)))


func can_use(id: String) -> bool:
	return learned(id) and remaining(id) <= 0.0 and m.glory >= float(data(id)["cost"]) and not m.busy()


func charging() -> bool:
	return _charge_t > 0.0


func shield_on() -> bool:
	return _shield_t > 0.0


func use(id: String, target: Vector2) -> bool:
	if id == "radiance" and learned(id) and remaining(id) <= 0.0:
		_toggle_radiance()
		return true
	if not can_use(id):
		return false
	var d: Dictionary = data(id)
	m.glory -= float(d["cost"])
	cooldowns[id] = m.stats.cooldown(float(d["cooldown"]))
	m.aim_at(target)
	m.face_toward(m.aim())
	if id == "descent" and m.inv.has_proc("descent_cdr"):
		cooldowns[id] = float(cooldowns[id]) * 0.5
	match id:
		"descent": _descent(target)
		"rebuke": _rebuke()
		"shield": _shield()
		"trumpet": _trumpet()
		"whirl": _whirl()
		"bash": _bash(target)
		"silence": _silence()
		"gale": _gale(target)
		"lance": _lance(target)
	used.emit(id)
	return true


func _process(delta: float) -> void:
	for id: String in cooldowns:
		cooldowns[id] = float(cooldowns[id]) - delta
	if _shield_t > 0.0:
		_shield_t -= delta
		_shield_fx.visible = _shield_t > 0.0
		_shield_fx.queue_redraw()
	if _charge_t > 0.0:
		_charge_t -= delta
		if _charge_t <= 0.0:
			_land()
	_update_radiance(delta)


# ------------------------------------------------------------------ Strike (LMB): called by Michael at the swing's hit frame
func strike_hit(aim: Vector2, combo: int) -> void:
	var d: Dictionary = data("strike")
	var wide: float = 1.25 if m.prog.has_mod("strike", "wide_arc") else 1.0
	var radius: float = float(d["radius"]) * wide * (1.15 if combo == 2 else 1.0)
	var arc: float = float(d["arc"]) * wide * (1.3 if combo == 2 else 1.0)
	var mult: float = float(d["damage"][combo]) * m.prog.rank_mult("strike")
	if combo == 2 and m.prog.has_mod("strike", "heavy_blow"):
		mult *= 1.5
	var center: Vector2 = m.global_position + Vector2(0, -20)
	SkillFx.arc(m.get_parent(), center, radius, aim.angle(), arc, PALE)
	var n: int = 0
	for dm: Demon in _demons_within(center, radius + 14.0):
		var to: Vector2 = dm.global_position + Vector2(0, -16) - center
		if absf(rad_to_deg(aim.angle_to(to))) <= arc / 2.0 + 12.0:
			_damage(dm, mult, 70.0 if combo < 2 else 150.0)
			if combo == 2 and m.prog.has_mod("strike", "heavy_blow"):
				dm.stun(0.5)
			n += 1
	if n > 0:
		Audio.sfx("hit", -6.0, randf_range(0.9, 1.1))
		Audio.sfx("spark", -10.0, randf_range(0.9, 1.2))
		Impact.shake(m, 1.0 if combo < 2 else 2.0)
	if combo == 2 and m.inv.has_proc("strike_burst"):
		var at: Vector2 = center + aim * radius * 0.6
		Impact.blast(m.get_parent(), at, 60.0, PALE, 0.5)
		for dm: Demon in _demons_within(at, 60.0):
			_damage(dm, 0.6, 80.0)
		HitStop.trigger(get_tree(), 0.045 if combo < 2 else 0.08)
	hit_landed.emit(n)


# ------------------------------------------------------------------ Descent (RMB): a leap that lands with a blow
func _descent(target: Vector2) -> void:
	var d: Dictionary = data("descent")
	var reach: float = float(d["range"]) * (1.4 if m.prog.has_mod("descent", "long_reach") else 1.0)
	var to: Vector2 = target - m.global_position
	_charge_to = m.global_position + to.limit_length(reach)
	_charge_t = float(d["time"])
	m.velocity = (_charge_to - m.global_position) / _charge_t
	m.invulnerable = true
	Audio.sfx("dash", -6.0, 0.8)


func _land() -> void:
	var d: Dictionary = data("descent")
	m.velocity = Vector2.ZERO
	m.invulnerable = false
	var push: float = 260.0 if m.prog.has_mod("descent", "downdraft") else 90.0
	Impact.crater(m.get_parent(), m.global_position, float(d["radius"]) * 0.6)
	var n: int = 0
	for dm: Demon in _demons_within(m.global_position, float(d["radius"])):
		_damage(dm, float(d["damage"]) * m.prog.rank_mult("descent"), push)
		n += 1
	Audio.sfx("impact_heavy", -3.0)
	Audio.sfx("crunch", -8.0)
	if n > 0:
		HitStop.trigger(get_tree(), 0.07)


# ------------------------------------------------------------------ Rebuke (Jude 9)
func _rebuke() -> void:
	_rebuke_pulse()
	if m.inv.has_proc("rebuke_heal"):
		m.life = minf(m.stats.v("life"), m.life + m.stats.v("life") * 0.08)
	if m.prog.has_mod("rebuke", "echo"):
		get_tree().create_timer(0.55).timeout.connect(_rebuke_pulse)
	Audio.sfx("rebuke", -4.0)


func _rebuke_pulse() -> void:
	var d: Dictionary = data("rebuke")
	var fear: float = float(d["fear"]) * (1.6 if m.prog.has_mod("rebuke", "dread") else 1.0)
	Impact.blast(m.get_parent(), m.global_position + Vector2(0, -10), float(d["radius"]), GOLD, 0.8)
	for dm: Demon in _demons_within(m.global_position, float(d["radius"])):
		_damage(dm, float(d["damage"]) * m.prog.rank_mult("rebuke"), 120.0)
		dm.fear(fear)


# ------------------------------------------------------------------ Shield of Faith (Eph 6:16)
func _shield() -> void:
	_shield_t = float(data("shield")["duration"])
	_shield_fx.visible = true
	Audio.sfx("shield", -6.0)


func shield_reduce() -> float:
	return float(data("shield")["reduce"]) + (0.15 if m.prog.has_mod("shield", "steadfast") else 0.0)


func on_quench(at: Vector2) -> void:
	if m.prog.has_mod("shield", "quench"):
		m.life = minf(m.stats.v("life"), m.life + 4.0)
	if m.inv.has_proc("shield_reflect"):                   # the bolt flies back and strikes what is nearest
		var near: Array[Demon] = _demons_within(at, 400.0)
		if not near.is_empty():
			_damage(near[0], 1.0, 60.0, false)
			SkillFx.beam(m.get_parent(), at, near[0].global_position + Vector2(0, -24), Color("8fd3ff"))


func _draw_shield() -> void:
	var r: float = float(data("shield")["radius"])
	var pulse: float = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 120.0)
	_shield_fx.draw_circle(Vector2(0, -28), r, Color(0.55, 0.8, 1.0, 0.10 * pulse))
	_shield_fx.draw_arc(Vector2(0, -28), r, 0.0, TAU, 48, Color(0.65, 0.88, 1.0, 0.7 * pulse), 2.0)


# ------------------------------------------------------------------ Trumpet Call (1 Thess 4:16)
func _trumpet() -> void:
	var d: Dictionary = data("trumpet")
	var radius: float = float(d["radius"]) * (1.25 if m.prog.has_mod("trumpet", "resound") else 1.0)
	Impact.blast(m.get_parent(), m.global_position + Vector2(0, -10), radius, PALE, 1.6)
	SkillFx.ring(m.get_parent(), m.global_position + Vector2(0, -10), radius * 0.7, GOLD, 0.45)
	Audio.sfx("impact_heavy", -4.0, 0.8)
	for dm: Demon in _demons_within(m.global_position, radius):
		_damage(dm, float(d["damage"]) * m.prog.rank_mult("trumpet"), float(d["push"]) * 2.0)
		if m.prog.has_mod("trumpet", "shockwave"):
			dm.stun(1.5)
	Audio.sfx("trumpet", -3.0)
	HitStop.trigger(get_tree(), 0.09)


# ------------------------------------------------------------------ the second skill of each mastery
func _whirl() -> void:
	var d: Dictionary = data("whirl")
	var r: float = float(d["radius"]) * (1.3 if m.prog.has_mod("whirl", "momentum") else 1.0)
	var c: Vector2 = m.global_position + Vector2(0, -20)
	for i: int in 4:
		SkillFx.arc(m.get_parent(), c, r - i * 4.0, i * PI / 2.0, 120.0, PALE)
	for dm: Demon in _demons_within(m.global_position, r):
		_damage(dm, float(d["damage"]) * m.prog.rank_mult("whirl"), 110.0)
	Audio.sfx("swing", -6.0, 0.8)
	Audio.sfx("hit", -8.0, 0.9)
	Impact.shake(m, 1.5)


func _bash(target: Vector2) -> void:
	var d: Dictionary = data("bash")
	var dir: Vector2 = (target - m.global_position).normalized()
	SkillFx.arc(m.get_parent(), m.global_position + Vector2(0, -20), float(d["radius"]), dir.angle(), float(d["arc"]), SKY)
	var stun: float = float(d["stun"]) + (1.0 if m.prog.has_mod("bash", "daze") else 0.0)
	for dm: Demon in _demons_within(m.global_position, float(d["radius"])):
		if absf(rad_to_deg(dir.angle_to(dm.global_position - m.global_position))) <= float(d["arc"]) / 2.0 + 10.0:
			_damage(dm, float(d["damage"]) * m.prog.rank_mult("bash"), 200.0)
			dm.stun(stun)
	Audio.sfx("shield", -6.0, 0.7)
	Audio.sfx("impact_heavy", -10.0, 1.4)
	Impact.shake(m, 2.0)


func _silence() -> void:
	var d: Dictionary = data("silence")
	var long: float = float(d["silence"]) + (2.0 if m.prog.has_mod("silence", "long_silence") else 0.0)
	SkillFx.ring(m.get_parent(), m.global_position + Vector2(0, -10), float(d["radius"]), Color("c7dcd0"), 0.7)
	for dm: Demon in _demons_within(m.global_position, float(d["radius"])):
		dm.stun(long if dm.data["behaviour"] == "ranged" else float(d["stun"]))
	Audio.sfx("rebuke", -8.0, 1.4)


func _gale(target: Vector2) -> void:
	var d: Dictionary = data("gale")
	var reach: float = float(d["radius"]) * (1.3 if m.prog.has_mod("gale", "gust") else 1.0)
	var dir: Vector2 = (target - m.global_position).normalized()
	SkillFx.arc(m.get_parent(), m.global_position + Vector2(0, -20), reach * 0.6, dir.angle(), float(d["arc"]), Color("c7dcd0"))
	SkillFx.arc(m.get_parent(), m.global_position + Vector2(0, -20), reach, dir.angle(), float(d["arc"]), Color("c7dcd0"))
	for dm: Demon in _demons_within(m.global_position, reach):
		if absf(rad_to_deg(dir.angle_to(dm.global_position - m.global_position))) <= float(d["arc"]) / 2.0 + 10.0:
			_damage(dm, float(d["damage"]) * m.prog.rank_mult("gale"), float(d["push"]))
	Audio.sfx("dash", -4.0, 0.6)
	Impact.shake(m, 1.5)


func _lance(target: Vector2) -> void:
	var d: Dictionary = data("lance")
	var length: float = float(d["length"]) * (1.5 if m.prog.has_mod("lance", "pierce") else 1.0)
	var from: Vector2 = m.global_position + Vector2(0, -28)
	var dir: Vector2 = (target - from).normalized()
	var to: Vector2 = from + dir * length
	SkillFx.beam(m.get_parent(), from, to, PALE)
	for dm: Demon in _demons_within(from + dir * length / 2.0, length / 2.0 + 20.0):
		var p: Vector2 = dm.global_position + Vector2(0, -20)
		var t: float = clampf((p - from).dot(dir), 0.0, length)
		if (from + dir * t).distance_to(p) < float(d["width"]) + float(dm.data["radius"]):
			_damage(dm, float(d["damage"]) * m.prog.rank_mult("lance"), 60.0)
	Audio.sfx("trumpet", -14.0, 2.0)
	Audio.sfx("spark", -6.0, 0.8)
	Impact.shake(m, 1.2)


# ------------------------------------------------------------------ Radiance (Ps 34:7), a toggle
func _toggle_radiance() -> void:
	radiance_on = not radiance_on and m.glory > 5.0
	cooldowns["radiance"] = float(data("radiance")["cooldown"])
	Audio.sfx("pickup", -10.0, 0.6 if radiance_on else 0.45)


func _update_radiance(delta: float) -> void:
	_radiance_fx.energy = move_toward(_radiance_fx.energy, 0.9 if radiance_on else 0.0, delta * 3.0)
	if not radiance_on:
		return
	var d: Dictionary = data("radiance")
	m.glory -= float(d["upkeep"]) * delta
	if m.glory <= 0.0:
		radiance_on = false
		return
	_radiance_tick -= delta
	if _radiance_tick > 0.0:
		return
	_radiance_tick = 0.5
	var mult: float = float(d["dps"]) * 0.5 * m.prog.rank_mult("radiance") * (1.4 if m.prog.has_mod("radiance", "kindle") else 1.0)
	for dm: Demon in _demons_within(m.global_position, float(d["radius"])):
		_damage(dm, mult, 0.0, false)
	var heal: float = float(d["heal"]) * (2.0 if m.prog.has_mod("radiance", "mending") else 1.0)
	m.life = minf(m.stats.v("life"), m.life + m.stats.v("life") * heal * 0.5)


# ------------------------------------------------------------------ shared
func _demons_within(at: Vector2, r: float) -> Array[Demon]:
	var out: Array[Demon] = []
	for n: Node in get_tree().get_nodes_in_group("demons"):
		var dm := n as Demon
		if dm != null and not dm.dead and dm.global_position.distance_to(at) <= r + float(dm.data["radius"]):
			out.append(dm)
	return out


func _damage(dm: Demon, mult: float, push: float, gain: bool = true) -> void:
	var roll: Vector2 = m.stats.roll_damage(mult)
	dm.hurt(roll.x, m.global_position, push, roll.y > 0.0)
	if gain:
		m.glory = minf(m.stats.v("glory"), m.glory + float(GameData.skills["glory_on_hit"]))
		m.life = minf(m.stats.v("life"), m.life + m.stats.v("life_on_hit"))
