class_name SmokeEnemies
extends RefCounted
## Smoke checks of the enemies, in an open spot of the Gloomwood: a shooter keeps its distance and always warns
## (a glow and a chime) 0.6 to 0.9 s before its shot leaves; the boss's ground attacks and volleys give the same
## warning; the elite's shield shrugs off the primary, breaks under the heavy, and only then can its body be hurt;
## the boss turns to phase two at half health (invulnerable for a moment) and summons ghosts.

const SPOT: Vector3 = Vector3(140.0, 0.0, 26.0)
const WARN_MIN: float = 0.6
const WARN_MAX: float = 0.95
const WATCH_SECONDS: float = 9.0

var m: Main
var failures: Array[String] = []
var _shot_warnings: Array[float] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	m.controller.enabled = false
	m.kit_input.enabled = false
	m.player.global_position = SPOT
	m.roster.child_entered_tree.connect(_on_child)
	await _shooter()
	await _boss_telegraphs()
	await _elite()
	await _boss_phases()
	m.roster.child_entered_tree.disconnect(_on_child)
	m.roster.clear()
	m.health.reset()
	return failures


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


## Times each enemy shot against the warning before it.
func _on_child(node: Node) -> void:
	if node is EnemyShot:
		_shot_warnings.append(m.roster.clock - m.roster.last_warned)


func _keep_player_alive() -> void:
	m.health.reset()
	m.health.invulnerable = true


func _shooter() -> void:
	_keep_player_alive()
	_shot_warnings.clear()
	var moth: Enemy = m.roster.spawn("lantern_moth", SPOT + Vector3(-12.0, 0.0, 0.0))
	await m.get_tree().create_timer(WATCH_SECONDS).timeout
	var far: float = Vector2(moth.global_position.x - SPOT.x, moth.global_position.z - SPOT.z).length()
	print("SMOKE shooter: %d shots, warnings %s s, keeps %.1f m away" % [_shot_warnings.size(), _shot_warnings, far])
	_expect(_shot_warnings.size() >= 2, "the shooter fires (%d shots)" % _shot_warnings.size())
	_check_warnings(_shot_warnings, "shooter shot")
	_expect(far > float(moth.spec["keep_near"]) - 2.0, "the shooter keeps its distance (%.1f m)" % far)
	m.roster.clear()
	await m.get_tree().process_frame


func _check_warnings(warnings: Array[float], what: String) -> void:
	for warned: float in warnings:
		_expect(warned >= WARN_MIN and warned <= WARN_MAX, "%s warned %.2f s ahead (want %.1f to %.1f)" % [what,
			warned, WARN_MIN, WARN_MAX])


func _boss_telegraphs() -> void:
	_keep_player_alive()
	_shot_warnings.clear()
	m.roster.strikes.clear()
	var boss: Enemy = m.roster.spawn("gloom_king", SPOT + Vector3(-9.0, 0.0, 0.0))
	await m.get_tree().create_timer(WATCH_SECONDS * 1.5).timeout
	var ground: Array[float] = []
	for strike: Dictionary in m.roster.strikes:
		if strike.get("ground", false):
			ground.append(float(strike["warned"]))
	print("SMOKE boss: %d ground attacks resolved, warnings %s; %d volley shots" % [ground.size(), ground,
		_shot_warnings.size()])
	_expect(ground.size() >= 2, "the boss's ground attacks land (%d)" % ground.size())
	_check_warnings(ground, "boss ground attack")
	_check_warnings(_shot_warnings, "boss volley shot")
	_expect(boss.is_alive(), "the boss is still standing")
	m.roster.clear()
	await m.get_tree().process_frame


func _elite() -> void:
	_keep_player_alive()
	var elite: Enemy = m.roster.spawn("scarecrow_knight", SPOT + Vector3(-6.0, 0.0, 0.0))
	elite.set_physics_process(false)
	var broken: Array[bool] = [false]
	elite.shield_broken.connect(func(_who: Enemy) -> void: broken[0] = true)
	elite.take_hit(Hit.new(Tuning.number("combat", "primary", "damage"), "primary", elite.centre()))
	var shield_after_primary: float = elite.shield
	_expect(elite.health == elite.max_health, "the shield protects the elite's body")
	_expect(elite.max_shield - shield_after_primary < Tuning.number("combat", "primary", "damage") * 0.5,
		"the primary barely scratches the shield")
	elite.take_hit(Hit.new(HeavyBeam.damage_for(1.0), "heavy", elite.centre()))
	print("SMOKE elite: shield %.0f -> %.0f after a primary, %.0f after a full heavy" % [elite.max_shield,
		shield_after_primary, elite.shield])
	_expect(broken[0] and elite.shield == 0.0, "a full heavy breaks the elite's shield")
	elite.take_hit(Hit.new(Tuning.number("combat", "primary", "damage"), "primary", elite.centre()))
	_expect(elite.health < elite.max_health, "after the break the elite's body can be hurt")
	m.roster.clear()
	await m.get_tree().process_frame


func _boss_phases() -> void:
	_keep_player_alive()
	var boss: Enemy = m.roster.spawn("gloom_king", SPOT + Vector3(-9.0, 0.0, 0.0))
	var phases: Array[int] = []
	var note_phase: Callable = func(_who: Enemy, phase: int) -> void: phases.append(phase)
	m.roster.boss_phase_changed.connect(note_phase, CONNECT_ONE_SHOT)
	await m.get_tree().create_timer(Tuning.number("combat", "enemy", "spawn_seconds") + 0.2).timeout
	var share: float = float(boss.spec["phase_two_share"])
	boss.take_hit(Hit.new(boss.max_health * (1.0 - share) + 1.0, "heavy", boss.centre()))
	await m.get_tree().physics_frame
	await m.get_tree().physics_frame
	_expect(phases.size() == 1 and phases[0] == 2 and (boss.brain as BossBrain).phase == 2,
		"the boss turns to phase two at half health")
	var landed: float = boss.take_hit(Hit.new(100.0, "heavy", boss.centre()))
	_expect(landed == 0.0, "the boss can't be hurt while changing phase")
	await m.get_tree().create_timer(float(boss.spec["phase_change_seconds"]) + 0.5).timeout
	var adds: int = m.roster.count_of(boss.spec["summon"])
	print("SMOKE boss phase two: %d ghosts summoned" % adds)
	_expect(adds > 0, "the boss summons ghosts in phase two")
	m.health.invulnerable = false
