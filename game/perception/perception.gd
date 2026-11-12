class_name Perception
extends Node
## The bot's senses. Eyes: a vision cone with a line-of-sight ray (trees, rocks, logs and the ground block it). A
## target hidden in a bush or tall grass is invisible unless very close, or unless the bot watched it go in. Ears:
## any sound the target makes within its radius (running is loud, sneaking quiet, attacks loud). Memory: the last
## known position and heading, and every snare it saw or heard being set (or spotted up close while searching).

var sees_target: bool = false
var time_since_seen: float = INF
var time_since_heard: float = INF
var last_known_position: Vector3 = Vector3.ZERO
var last_known_heading: Vector3 = Vector3.ZERO
var has_lead: bool = false
var searching_carefully: bool = false
var known_snares: Array[Vector3] = []
var _bot: Creature
var _target: Creature
var _fresh_lead: bool = false
var _saw_enter_spot: HidingSpot
var _was_seeing_in_open: bool = false


func setup(bot: Creature, target: Creature) -> void:
	_bot = bot
	_target = target
	name = "Perception"
	NoiseBus.noise_made.connect(_on_noise)
	bot.hit_taken.connect(_on_hit_taken)


func tick(delta: float) -> void:
	_remember_hiding_spot_entry()
	sees_target = can_see_target()
	time_since_heard += delta
	if sees_target:
		time_since_seen = 0.0
		_track_target()
	else:
		time_since_seen += delta
	_was_seeing_in_open = sees_target and not _target.stealth.is_hidden()
	if searching_carefully:
		_spot_snares_close_by()
	_bot.aware_of_opponent = time_since_seen <= Tuning.f("stealth", "unaware_memory")


func can_see_target() -> bool:
	if _target.is_dead():
		return false
	var to_target: Vector3 = _target.chest_position() - _bot.eye_position()
	var distance: float = to_target.length()
	if distance > Tuning.f("perception", "vision_range"):
		return false
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	var in_cone: bool = _bot.forward().angle_to(flat) <= Tuning.degrees("perception", "vision_half_angle_deg")
	if not in_cone and distance > Tuning.f("perception", "close_awareness"):
		return false
	if _hidden_from_me(distance):
		return false
	return Sight.clear(_bot.get_world_3d(), _bot.eye_position(), _target.chest_position())


## True once per new clue (a sound, a hit), so states can react to it exactly once.
func take_fresh_lead() -> bool:
	var fresh: bool = _fresh_lead
	_fresh_lead = false
	return fresh


func heard_recently() -> bool:
	return time_since_heard <= Tuning.f("perception", "heard_display_time")


func note_clue(where: Vector3) -> void:
	last_known_position = where
	has_lead = true
	_fresh_lead = true


func knows_snare_near(point: Vector3, reach: float) -> bool:
	for snare: Vector3 in known_snares:
		if Vector2(point.x - snare.x, point.z - snare.z).length() <= reach:
			return true
	return false


func _hidden_from_me(distance: float) -> bool:
	if not _target.stealth.is_hidden() or distance <= Tuning.f("stealth", "reveal_distance"):
		return false
	return _target.stealth.current_spot() != _saw_enter_spot


## If we were watching the target in the open and it now ducks into a bush, we know which bush.
func _remember_hiding_spot_entry() -> void:
	if not _target.stealth.in_cover():
		_saw_enter_spot = null
	elif _was_seeing_in_open:
		_saw_enter_spot = _target.stealth.current_spot()


func _track_target() -> void:
	last_known_position = _target.global_position
	var moving := Vector3(_target.velocity.x, 0.0, _target.velocity.z)
	if moving.length() > Creature.MOVING_SPEED:
		last_known_heading = moving.normalized()
	has_lead = true
	if _target.trap.phase == Ability.Phase.WINDUP:
		_remember_snare(_target.trap.place_spot)


func _spot_snares_close_by() -> void:
	for node: Node in get_tree().get_nodes_in_group("snares"):
		var snare := node as SnareTrap
		if snare.owner_creature == _target and not snare.sprung \
				and _bot.global_position.distance_to(snare.global_position) <= Tuning.f("trap", "spot_distance"):
			_remember_snare(snare.global_position)


func _remember_snare(where: Vector3) -> void:
	if not knows_snare_near(where, Tuning.f("trap", "trigger_radius")):
		known_snares.append(where)


func _on_noise(source: Node3D, origin: Vector3, radius: float, kind: String) -> void:
	if source != _target or _bot.global_position.distance_to(origin) > radius:
		return
	time_since_heard = 0.0
	if kind == "trap":
		_remember_snare(origin)
	if not sees_target:
		note_clue(origin)


func _on_hit_taken(_amount: float, attacker: Creature, _ambush: bool, _kind: String) -> void:
	if attacker == _target:
		note_clue(attacker.global_position)
