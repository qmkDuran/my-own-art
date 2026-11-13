class_name PlayerWatcher
extends Node
## Feeds the PlayerModel from the bot's own senses only: where it watched (or found) the player hiding, which moves it
## saw them use, how soon after its own wind-up they rolled, time on high ground, and which way a hurt player ran.
## Learning raises a short "learning" flash and a bark for the F3 overlay.

var _brain: BotBrain
var _model: PlayerModel
var _target: Creature
var _observe_left: float = 0.0
var _noted_spot: HidingSpot
var _windup_started: float = INF
var _was_rolling: bool = false
var _own_winding: bool = false


func setup(brain: BotBrain, model: PlayerModel) -> void:
	_brain = brain
	_model = model
	_target = brain.target
	name = "PlayerWatcher"
	model.learned.connect(_on_learned)
	_target.move_started.connect(_on_target_move)


func tick(delta: float) -> void:
	_windup_started += delta
	var own_winding: bool = false
	for move: Move in _brain.bot.moves:
		own_winding = own_winding or move.phase == Ability.Phase.WINDUP
	if own_winding and not _own_winding:
		_windup_started = 0.0
	_own_winding = own_winding
	if not _brain.senses.sees_target:
		_was_rolling = false
		return
	_watch_hiding()
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


## Only moves it can see (or a burrow it hears rumbling) are learned.
func _on_target_move(move: Move) -> void:
	if _brain.senses.sees_target or _brain.senses.heard_recently():
		_model.note_move(move.role())


func _watch_rolls() -> void:
	var rolling: bool = _target.roll.protects()
	if rolling and not _was_rolling and _windup_started <= Tuning.ai_f("memory", "roll_watch_window"):
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


func _on_learned(what: String) -> void:
	_brain.note_learning("It learns that " + what + ".")
