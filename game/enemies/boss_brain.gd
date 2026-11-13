class_name BossBrain
extends EnemyBrain
## The Gloom King: drifts at a middle distance and works through his attacks, each telegraphed on the ground or by
## a glow (data/combat.json gloom_king.attacks): candle circles under and around the player, a gloom wave along a
## line, a fan volley of shots, and in phase two a nova around himself. At half health he roars (invulnerable for a
## moment), his aura flares, attacks come faster and he keeps summoning ghosts.

const SUMMON_RING: float = 3.0
const DRIFT_SHARE: float = 0.6

var phase: int = 1
var _rest: float = 2.0
var _turn: int = 0
var _busy: int = 0
var _changing: float = 0.0
var _summon: float = 0.0
var _volley_in: float = -1.0


func think(enemy: Enemy, delta: float) -> void:
	enemy.look_at_point = enemy.roster.player.global_position
	if _changing > 0.0:
		_changing -= delta
		enemy.wish = Vector3.ZERO
		if _changing <= 0.0:
			enemy.invulnerable = false
			_summon_adds(enemy)
		return
	_drift(enemy)
	if phase == 1 and enemy.health <= enemy.max_health * float(enemy.spec["phase_two_share"]):
		_enter_phase_two(enemy)
		return
	if phase == 2:
		_summon -= delta
		if _summon <= 0.0:
			_summon_adds(enemy)
	if _volley_in >= 0.0:
		_volley_in -= delta
		if _volley_in < 0.0:
			_fire_volley(enemy)
		return
	if _busy > 0:
		return
	_rest -= delta
	if _rest <= 0.0:
		_next_attack(enemy)


func _drift(enemy: Enemy) -> void:
	var to: Vector3 = to_player(enemy)
	var radial: float = 0.0
	if to.length() < float(enemy.spec["keep_near"]):
		radial = -1.0
	elif to.length() > float(enemy.spec["keep_far"]):
		radial = 1.0
	enemy.wish = to.normalized() * radial * DRIFT_SHARE


func _enter_phase_two(enemy: Enemy) -> void:
	phase = 2
	enemy.invulnerable = true
	_changing = float(enemy.spec["phase_change_seconds"])
	_summon = float(enemy.spec["summon_every"])
	_rest = float(enemy.spec["phase_change_seconds"])
	enemy.look().phase_two()
	enemy.roster.boss_phase_changed.emit(enemy, phase)


func _summon_adds(enemy: Enemy) -> void:
	_summon = float(enemy.spec["summon_every"])
	var room: int = int(enemy.spec["max_adds"]) - enemy.roster.count_of(enemy.spec["summon"])
	var count: int = mini(int(enemy.spec["summon_count"]), room)
	for index: int in count:
		var angle: float = TAU * index / maxf(count, 1.0) + randf()
		enemy.roster.spawn(enemy.spec["summon"], enemy.global_position + Vector3(cos(angle), 0.0, sin(angle)) *
			SUMMON_RING)


func _next_attack(enemy: Enemy) -> void:
	var order: Array = enemy.spec["phase_one" if phase == 1 else "phase_two"]
	var attack: String = order[_turn % order.size()]
	_turn += 1
	var spec: Dictionary = enemy.spec["attacks"][attack]
	var pace: float = float(enemy.spec["phase_two_speedup"]) if phase == 2 else 1.0
	_rest = float(spec["rest"]) * pace
	match attack:
		"candle_circles":
			_candle_circles(enemy, spec)
		"gloom_wave":
			var direction: Vector3 = to_player(enemy).normalized()
			_track(Telegraph.line(enemy.roster, enemy.global_position, direction, float(spec["length"]),
				float(spec["width"]), float(spec["telegraph"]), float(spec["damage"])))
		"volley":
			_volley_in = float(spec["telegraph"])
			enemy.look().charge(_volley_in)
			enemy.roster.warn(enemy)
		"nova":
			_track(Telegraph.circle(enemy.roster, enemy.global_position, float(spec["radius"]),
				float(spec["telegraph"]), float(spec["damage"])))


func _candle_circles(enemy: Enemy, spec: Dictionary) -> void:
	var around: Vector3 = enemy.roster.player.global_position
	for index: int in int(spec["count"]):
		var at: Vector3 = around
		if index > 0:
			var angle: float = TAU * index / float(spec["count"]) + randf()
			at += Vector3(cos(angle), 0.0, sin(angle)) * float(spec["spread"]) * randf_range(DRIFT_SHARE, 1.0)
		_track(Telegraph.circle(enemy.roster, at, float(spec["radius"]), float(spec["telegraph"]),
			float(spec["damage"])))


func _track(telegraph: Telegraph) -> void:
	_busy += 1
	telegraph.finished.connect(func() -> void: _busy = maxi(_busy - 1, 0))


func _fire_volley(enemy: Enemy) -> void:
	var spec: Dictionary = enemy.spec["attacks"]["volley"]
	var from: Vector3 = enemy.look().muzzle()
	var aim: Vector3 = from.direction_to(player_chest(enemy))
	var shots: int = int(spec["shots"])
	var fan: float = deg_to_rad(float(spec["fan_deg"]))
	for index: int in shots:
		var turn: float = lerpf(-fan * 0.5, fan * 0.5, float(index) / maxf(shots - 1, 1.0))
		EnemyShot.fire(enemy.roster, from, aim.rotated(Vector3.UP, turn), float(spec["shot_speed"]),
			float(spec["damage"]), float(spec["shot_radius"]), float(spec["telegraph"]))
