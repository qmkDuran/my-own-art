class_name PlayerWatcher
extends Node
## Feeds the PlayerModel from the bot's own senses only: where it watched (or found) the player hiding, which attack
## it saw them start, how soon after its own wind-up they rolled, time on high ground, snares it learned of, and
## which way a hurt player ran. Learning raises a short "learning" flash and a bark for the F3 overlay.

var _brain: BotBrain
var _model: PlayerModel
var _target: Creature
var _observe_left: float = 0.0
var _noted_spot: HidingSpot
var _windup_started: float = INF
var _was_rolling: bool = false
var _target_winding: bool = false
var _own_winding: bool = false
var _snares_known: int = 0


func setup(brain: BotBrain, model: PlayerModel) -> void:
	_brain = brain
	_model = model
	_target = brain.target
	name = "PlayerWatcher"
	model.learned.connect(_on_learned)


func tick(delta: float) -> void:
	_windup_started += delta
	var bot: Creature = _brain.bot
	var own_winding: bool = bot.bite.phase == Ability.Phase.WINDUP or bot.spit.phase == Ability.Phase.WINDUP
	if own_winding and not _own_winding:
		_windup_started = 0.0
	_own_winding = own_winding
	_watch_snares()
	if not _brain.senses.sees_target:
		_was_rolling = false
		return
	_watch_hiding()
	_watch_attacks()
	_watch_rolls()
	_observe_left -= delta
	if _observe_left <= 0.0:
		_observe_left = Tuning.ai_f("memory", "observe_interval")
		_watch_position()


func _watch_hiding() -> void:
	var spot: HidingSpot = _target.stealth.current_spot()
	if spot == null:
		_noted_spot = null
	elif spot != _noted_spot:
		_noted_spot = spot
		_model.note_hide(spot)


func _watch_attacks() -> void:
	var winding: bool = _target.bite.phase == Ability.Phase.WINDUP or _target.spit.phase == Ability.Phase.WINDUP
	if winding and not _target_winding:
		_model.note_attack("bite" if _target.bite.phase == Ability.Phase.WINDUP else "spit")
	_target_winding = winding


func _watch_rolls() -> void:
	var rolling: bool = _target.dodge.protects()
	if rolling and not _was_rolling and _windup_started <= _brain.bot.spit.windup_time:
		_model.note_roll_delay(_windup_started)
	_was_rolling = rolling


func _watch_position() -> void:
	var lift: float = _brain.woods.shape.ridge_lift(Vector2(_target.global_position.x, _target.global_position.z))
	_model.note_position(lift >= Tuning.ai_f("memory", "high_ground_lift"))
	var away: Vector3 = _target.global_position - _brain.bot.global_position
	away.y = 0.0
	var fleeing: bool = _brain.senses.observed_velocity.dot(away.normalized()) > Creature.MOVING_SPEED
	if _brain.senses.target_life_seen <= Tuning.ai_f("memory", "flee_life_fraction") and fleeing:
		_model.note_flee(_brain.senses.observed_velocity.normalized())


func _watch_snares() -> void:
	var known: Array[Vector3] = _brain.senses.known_snares
	while _snares_known < known.size():
		_model.note_snare(known[_snares_known])
		_snares_known += 1


func _on_learned(what: String) -> void:
	_brain.note_learning("It learns that " + what + ".")
