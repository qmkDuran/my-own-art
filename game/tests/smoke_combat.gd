class_name SmokeCombat
extends RefCounted
## Smoke checks of the Lamplighter's kit, in an open spot of the Gloomwood with still target dummies: the primary
## fires, hits and keeps its fire rate; the heavy's damage grows with its charge and it respects its cooldown; the
## bomb lands where its arc was previewed and hurts what is there; the ward stops an enemy shot (and a shot hurts
## without it); the blink dashes and cools down; the super meter fills from damage and the Sunrise fires, rains
## motes that hurt, and ends with the Lamplighter back on the ground.

const SPOT: Vector3 = Vector3(140.0, 0.0, 26.0)
const AHEAD: Vector3 = Vector3(-7.0, 0.0, 0.0)
const TOUGH: float = 5000.0
const LAND_TOLERANCE: float = 0.05
const SETTLE: float = 0.3

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	await _stand()
	await _primary()
	await _heavy()
	await _bomb()
	await _ward()
	await _blink()
	await _super()
	m.kit.aim.lock(null)
	m.roster.clear()
	return failures


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _stand() -> void:
	m.controller.enabled = false
	m.kit_input.enabled = false
	m.player.global_position = SPOT
	m.player.yaw = PI * 0.5
	m.camera_rig.yaw = PI * 0.5
	m.camera_rig.snap()
	await m.get_tree().create_timer(SETTLE).timeout


## A still dummy ahead of the player (no brain running), locked on so every attack aims at it.
func _dummy(kind: String, offset: Vector3 = AHEAD) -> Enemy:
	var enemy: Enemy = m.roster.spawn(kind, SPOT + offset)
	enemy.set_physics_process(false)
	enemy.health = TOUGH
	enemy.max_health = TOUGH
	m.kit.aim.lock(enemy)
	return enemy


func _clear() -> void:
	m.kit.aim.lock(null)
	m.roster.clear()
	await m.get_tree().process_frame


func _primary() -> void:
	var dummy: Enemy = _dummy("pumpkin_head")
	await m.get_tree().physics_frame
	var meter_before: float = m.kit.meter.charge
	_expect(m.kit.primary.trigger(), "the primary fires")
	_expect(not m.kit.primary.trigger(), "the primary waits for its fire interval")
	await m.get_tree().create_timer(SETTLE * 2.0).timeout
	_expect(dummy.health < TOUGH, "a primary bolt hits (health %.0f)" % dummy.health)
	_expect(m.kit.meter.charge > meter_before, "damage dealt fills the super meter")
	await _clear()


func _heavy() -> void:
	_expect(HeavyBeam.damage_for(1.0) > HeavyBeam.damage_for(0.5) and HeavyBeam.damage_for(0.5) >
		HeavyBeam.damage_for(0.0), "the heavy's damage grows with its charge")
	var dummy: Enemy = _dummy("pumpkin_head")
	await m.get_tree().physics_frame
	_expect(m.kit.heavy.begin(), "the heavy starts charging")
	await m.get_tree().create_timer(Tuning.number("combat", "heavy", "full_charge") * 0.25).timeout
	var weak: float = m.kit.heavy.release()
	var after_weak: float = dummy.health
	_expect(after_weak < TOUGH, "a quick heavy beam hits (health %.0f)" % after_weak)
	_expect(not m.kit.heavy.begin(), "the heavy respects its cooldown")
	await m.get_tree().create_timer(Tuning.number("combat", "heavy", "cooldown") + SETTLE).timeout
	_expect(m.kit.heavy.begin(), "the heavy charges again after its cooldown")
	await m.get_tree().create_timer(Tuning.number("combat", "heavy", "full_charge") + SETTLE).timeout
	var strong: float = m.kit.heavy.release()
	print("SMOKE heavy: a quick release %.0f damage, a full charge %.0f" % [weak, strong])
	_expect(strong > weak * 2.0, "a full charge hits much harder (%.0f vs %.0f)" % [strong, weak])
	_expect(is_equal_approx(after_weak - dummy.health, strong), "the full beam lands its full damage")
	await _clear()


func _bomb() -> void:
	var dummy: Enemy = _dummy("pumpkin_head", AHEAD * 1.4)
	await m.get_tree().physics_frame
	_expect(m.kit.bomb.begin_aim(), "the bomb aims")
	await m.get_tree().create_timer(SETTLE).timeout
	var previewed: Vector3 = m.kit.bomb.current_arc().landing
	var shell: BombShell = m.kit.bomb.release()
	_expect(shell != null and not m.kit.bomb.begin_aim(), "the bomb throws, then waits for its cooldown")
	var landed: Array[Vector3] = [Vector3.INF]
	shell.tree_exiting.connect(func() -> void: landed[0] = shell.global_position)
	while is_instance_valid(shell):
		await m.get_tree().physics_frame
	var miss: float = landed[0].distance_to(previewed)
	print("SMOKE bomb: previewed %s, burst at %s (%.3f m)" % [previewed, landed[0], miss])
	_expect(miss < LAND_TOLERANCE, "the bomb bursts where the arc was previewed (%.2f m off)" % miss)
	_expect(dummy.health < TOUGH, "the bomb's burst hurts the enemy there")
	await _clear()


func _ward() -> void:
	var shooter_at: Vector3 = SPOT + AHEAD * 1.5 + Vector3.UP * Tuning.number("combat", "player", "chest_height")
	var chest: Vector3 = EnemyBrain.player_chest_of(m.player)
	m.health.reset()
	_expect(m.kit.ward.raise(), "the ward rises")
	_expect(not m.kit.ward.raise(), "the ward respects its cooldown")
	EnemyShot.fire(m.roster, shooter_at, shooter_at.direction_to(chest), 12.0, 10.0, 0.35, 0.75)
	await m.get_tree().create_timer(1.5).timeout
	_expect(m.health.health == m.health.max_health, "the ward blocks a shot (health %.0f)" % m.health.health)
	await m.get_tree().create_timer(Tuning.number("combat", "ward", "seconds")).timeout
	_expect(not m.kit.ward.active, "the ward fades after its time")
	EnemyShot.fire(m.roster, shooter_at, shooter_at.direction_to(chest), 12.0, 10.0, 0.35, 0.75)
	await m.get_tree().create_timer(1.5).timeout
	_expect(m.health.health < m.health.max_health, "without the ward the shot hurts")
	m.health.reset()
	await _clear()


func _blink() -> void:
	await m.get_tree().create_timer(SETTLE).timeout
	var start: Vector3 = m.player.global_position
	_expect(m.kit.blink.go(), "the blink dashes")
	_expect(m.player.is_dashing() and not m.health.can_be_hurt(), "nothing can hurt the Lamplighter mid-blink")
	_expect(not m.kit.blink.go(), "the blink respects its cooldown")
	await m.get_tree().create_timer(SETTLE).timeout
	_expect(m.player.global_position.distance_to(start) > 0.5, "the blink moves the Lamplighter")
	m.player.global_position = SPOT


func _super() -> void:
	var dummy: Enemy = _dummy("pumpkin_head", AHEAD * 0.6)
	m.kit.meter.spend()
	_expect(not m.kit.sunrise.fire(), "the Sunrise needs a full meter")
	m.kit.meter.add(SuperMeter.cost())
	_expect(m.kit.sunrise.fire(), "the Sunrise fires with a full meter")
	await m.get_tree().create_timer(Tuning.number("combat", "super", "rise_seconds") * 0.8).timeout
	_expect(m.player.global_position.y > SPOT.y + SETTLE, "the Lamplighter rises into the air")
	_expect(not m.health.can_be_hurt(), "the Lamplighter can't be hurt during the Sunrise")
	while m.kit.sunrise.active:
		await m.get_tree().physics_frame
	print("SMOKE super: %d motes, the dummy took %.0f damage" % [m.kit.sunrise.motes_fired, TOUGH - dummy.health])
	_expect(m.kit.sunrise.motes_fired > 20, "the Sunrise rains motes (%d)" % m.kit.sunrise.motes_fired)
	_expect(dummy.health < TOUGH, "the Sunrise's motes hurt enemies")
	_expect(absf(m.player.global_position.y - SPOT.y) < SETTLE and m.health.can_be_hurt(),
		"the Lamplighter lands again afterwards")
	_expect(m.kit.meter.charge < SuperMeter.cost(), "the Sunrise spends the meter")
	await _clear()
