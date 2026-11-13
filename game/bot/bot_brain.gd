class_name BotBrain
extends Node
## The bot's mind. Senses, reflexes and a habit watcher run every physics frame; every think interval (shorter on
## Hard) a utility selector scores the options in data/ai.json against the bot's facts and the matching state
## carries the choice out. A first sound or sighting while idle triggers a short "notice" beat (its reaction
## time). Tactical point evaluation, prediction and the learned player model feed both the facts and the states.

signal state_changed(state_name: String)
signal decided(option: String, scores: Dictionary)

enum Alert { HIDDEN, HEARD, SEEN }

const MARKERS: Dictionary = { "notice": "!", "search": "?", "chase": "!" }
const SUSPECT_REACH_KEY: String = "grass_suspect_reach"
const MARKER_COLORS: Dictionary = { "notice": Color(1.0, 0.85, 0.2), "search": Color(0.9, 0.9, 0.95),
	"chase": Color(1.0, 0.45, 0.2) }
const CALM_STATES: Array[String] = ["patrol", "retreat"]
const BARKS_KEPT: int = 6

var bot: Creature
var target: Creature
var woods: Woods
var senses: Perception
var mover: BotMover
var reflexes: BotReflexes
var tactics: TacticalEval
var model: PlayerModel
var watcher: PlayerWatcher
var selector: UtilitySelector
var rng := RandomNumberGenerator.new()
var state_name: String = ""
## When false the mind is paused (tests, staged stills): it still perceives, and the legs still follow mover
## commands, but no state runs and nothing is decided.
var active: bool = true
var since_retreat: float = INF
var since_cover: float = INF
var since_shot_hit: float = INF
var learning_left: float = 0.0
var barks: Array[String] = []
var last_facts: Dictionary = {}
var _states: Dictionary = {}
var _current: BotState
var _think_left: float = 0.0


func setup(bot_creature: Creature, target_creature: Creature, arena: Woods, habits: PlayerModel) -> void:
	bot = bot_creature
	target = target_creature
	woods = arena
	model = habits
	name = "BotBrain"
	rng.seed = Tuning.i("bot", "seed")
	senses = Perception.new()
	senses.setup(bot, target)
	bot.add_child(senses)
	mover = BotMover.new()
	mover.setup(bot, woods)
	bot.add_child(mover)
	reflexes = BotReflexes.new(bot, target, senses, rng)
	tactics = TacticalEval.new(woods, bot, senses, model)
	selector = UtilitySelector.new(rng)
	watcher = PlayerWatcher.new()
	watcher.setup(self, model)
	add_child(watcher)
	bot.hit_taken.connect(_on_hit_taken)
	_states = BotStates.all(self)
	change_state("patrol")


func change_state(next: String) -> void:
	if _current != null:
		_current.exit()
	state_name = next
	_current = _states[next]
	bot.model.show_marker(MARKERS.get(next, ""), MARKER_COLORS.get(next, Color.WHITE))
	_current.begin()
	state_changed.emit(next)


## How much the bot knows about the player, for the HUD's stealth eye.
func alert() -> Alert:
	if senses.sees_target:
		return Alert.SEEN
	if senses.heard_recently() or not CALM_STATES.has(state_name):
		return Alert.HEARD
	return Alert.HIDDEN


func current_done() -> bool:
	return _current.done


func memory_use() -> float:
	return Difficulty.setting("memory_use")


## Where the player probably is now: the last known spot pushed along the heading it was last seen moving.
func predicted_target() -> Vector3:
	if senses.sees_target:
		return senses.last_known_position
	var guess: Vector3 = Prediction.predicted_position(senses.last_known_position, senses.observed_velocity,
			senses.time_since_seen)
	return woods.on_navmesh(guess)


## The move that sets grass alight, if it has one equipped (Cinder Spit, Kindle).
func fire_move() -> Move:
	for move: Move in bot.moves:
		if move.spec.get("ignite", false):
			return move
	return null


## A tall-grass patch the player is probably hiding in (near where it is predicted to be), or null.
func suspect_grass() -> HidingSpot:
	if senses.sees_target or not senses.has_lead:
		return null
	var guess: Vector3 = predicted_target()
	for spot: HidingSpot in woods.hiding_spots:
		var reach: float = spot.radius + Tuning.ai_f("tactics", SUSPECT_REACH_KEY)
		var near: bool = spot.global_position.distance_to(guess) <= reach
		if spot.kind == "grass" and spot.conceals() and near:
			return spot
	return null


func bark(words: String) -> void:
	if barks.is_empty() or barks.back() != words:
		barks.append(words)
	while barks.size() > BARKS_KEPT:
		barks.pop_front()


func note_learning(words: String) -> void:
	learning_left = Tuning.ai_f("memory", "learning_flash")
	bark(words)


func _physics_process(delta: float) -> void:
	if bot.is_dead():
		return
	if active:
		_think(delta)
	else:
		senses.tick(delta)
	mover.tick(delta)


func _think(delta: float) -> void:
	since_retreat += delta
	since_cover += delta
	since_shot_hit += delta
	learning_left = maxf(0.0, learning_left - delta)
	senses.tick(delta)
	reflexes.tick(delta)
	watcher.tick(delta)
	_current.tick(delta)
	if state_name == "patrol" and (senses.sees_target or senses.take_fresh_lead()):
		change_state("notice")
	_think_left -= delta
	if (_think_left <= 0.0 or _current.done) and not _current.committed():
		_think_left = Difficulty.setting("think_interval")
		_decide()


func _decide() -> void:
	last_facts = BotFacts.gather(self)
	var finished: String = state_name if _current.done else ""
	var choice: String = selector.choose(last_facts, state_name, Difficulty.setting("score_noise"), finished)
	if choice == finished:
		choice = "patrol" if not senses.has_lead else "search"
	decided.emit(choice, selector.last_scores)
	if choice != state_name or _current.done:
		change_state(choice)


func _on_hit_taken(_amount: float, _attacker: Creature, _ambush: bool, kind: String) -> void:
	if Tuning.moves["moves"].has(kind) and MoveLibrary.spec(kind)["archetype"] == "projectile":
		since_shot_hit = 0.0


## -1 or +1 with equal odds (strafe sides, flank sides, roll sides).
static func random_side(dice: RandomNumberGenerator) -> float:
	return 1.0 if dice.randf() < 0.5 else -1.0
