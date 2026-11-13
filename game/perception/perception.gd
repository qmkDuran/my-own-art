class_name Perception
extends Node
## The bot's senses. Eyes: a vision cone with a line-of-sight ray (trees, rocks, logs and the ground block it). A
## target hidden in a bush or tall grass is invisible unless very close, or unless the bot watched it go in. Ears:
## any sound the target makes within its radius (running is loud, sneaking quiet, attacks loud). Memory: the last
## known position, heading and observed velocity, the target's life when last seen, when it last saw the target
## roll. Sense moves feed it too (a scent trail gives a fresh clue). Nothing is read from the player that the bot
## could not see or hear. The hiding rules themselves live in Visibility, shared with the player's view.

var sees_target: bool = false
var time_since_seen: float = INF
var time_since_heard: float = INF
var last_known_position: Vector3 = Vector3.ZERO
var last_known_heading: Vector3 = Vector3.ZERO
var has_lead: bool = false
var observed_velocity: Vector3 = Vector3.ZERO
var target_life_seen: float = 1.0
var since_roll_seen: float = INF
## The hiding spot the bot watched the target enter (null when none).
var watched_hiding_spot: HidingSpot:
	get:
		return _saw_enter_spot
var _bot: Creature
var _target: Creature
var _fresh_lead: bool = false
var _saw_enter_spot: HidingSpot
var _was_seeing_in_open: bool = false
var _last_seen_at: Vector3 = Vector3.INF


func setup(bot: Creature, target: Creature) -> void:
	_bot = bot
	_target = target
	name = "Perception"
	NoiseBus.noise_made.connect(_on_noise)
	bot.hit_taken.connect(_on_hit_taken)
	bot.sensed.connect(_on_sensed)


func tick(delta: float) -> void:
	_remember_hiding_spot_entry()
	sees_target = can_see_target()
	time_since_heard += delta
	since_roll_seen += delta
	if sees_target:
		time_since_seen = 0.0
		_track_target(delta)
	else:
		time_since_seen += delta
		_last_seen_at = Vector3.INF
	_was_seeing_in_open = sees_target and not _target.stealth.is_hidden()
	_bot.aware_of_opponent = time_since_seen <= Tuning.f("stealth", "unaware_memory")


func can_see_target() -> bool:
	if _target.is_dead():
		return false
	var to_target: Vector3 = _target.chest_position() - _bot.eye_position()
	var distance: float = to_target.length()
	if distance > Visibility.sight_range(_bot, Tuning.f("perception", "vision_range")):
		return false
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	var in_cone: bool = _bot.forward().angle_to(flat) <= Tuning.degrees("perception", "vision_half_angle_deg")
	if not in_cone and distance > Tuning.f("perception", "close_awareness"):
		return false
	if Visibility.hides(_target, distance, _saw_enter_spot):
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


## If we were watching the target in the open and it now ducks into a bush, we know which bush.
func _remember_hiding_spot_entry() -> void:
	if not _target.stealth.in_cover():
		_saw_enter_spot = null
	elif _was_seeing_in_open:
		_saw_enter_spot = _target.stealth.current_spot()


## Is the target's creature facing us right now? Only known while we can see it; unseen, assume it cannot see us.
func target_facing_me() -> bool:
	if not sees_target:
		return false
	var to_me: Vector3 = _bot.global_position - _target.global_position
	to_me.y = 0.0
	return _target.forward().angle_to(to_me) <= deg_to_rad(Tuning.ai_f("senses", "facing_half_angle_deg"))


## Is the target visibly winding up a move close enough to matter (a tell the bot can react to)?
func target_winding_up() -> bool:
	if not sees_target:
		return false
	for move: Move in _target.moves:
		if move.phase == Ability.Phase.WINDUP and move.category() == "attack" \
				and _bot.global_position.distance_to(_target.global_position) <= BotFacts.effective_range(move) + 1.0:
			return true
	return false


## Was the target last seen heading toward us?
func target_approaching() -> bool:
	var to_me: Vector3 = _bot.global_position - last_known_position
	to_me.y = 0.0
	return last_known_heading.dot(to_me.normalized()) >= Tuning.ai_f("senses", "approach_dot")


func _track_target(delta: float) -> void:
	_observe_motion(delta)
	target_life_seen = _target.health.fraction()
	if _target.roll.protects():
		since_roll_seen = 0.0
	last_known_position = _target.global_position
	has_lead = true


## Velocity and heading worked out from where we saw the target last frame and now (smoothed).
func _observe_motion(delta: float) -> void:
	if _last_seen_at != Vector3.INF:
		var step: Vector3 = (_target.global_position - _last_seen_at) / delta
		step.y = 0.0
		var blend: float = clampf(Tuning.ai_f("prediction", "velocity_smoothing") * delta, 0.0, 1.0)
		observed_velocity = observed_velocity.lerp(step, blend)
		if observed_velocity.length() > Creature.MOVING_SPEED:
			last_known_heading = observed_velocity.normalized()
	_last_seen_at = _target.global_position



func _on_noise(source: Node3D, origin: Vector3, radius: float, _kind: String) -> void:
	if source != _target or not Visibility.hears(_bot, origin, radius):
		return
	time_since_heard = 0.0
	if not sees_target:
		note_clue(origin)


func _on_hit_taken(_amount: float, attacker: Creature, _ambush: bool, _kind: String) -> void:
	if attacker == _target:
		note_clue(attacker.global_position)


## Scent Trail: the newest trail point is a fresh clue, and the trail gives the heading.
func _on_sensed(kind: String, points: Array) -> void:
	if kind != "scent" or points.is_empty():
		return
	var newest: Vector3 = points.back()
	if points.size() > 1:
		var heading: Vector3 = newest - (points[points.size() - 2] as Vector3)
		heading.y = 0.0
		if heading.length() > 0.0:
			last_known_heading = heading.normalized()
	note_clue(newest)
