class_name BotBrain
extends Node
## The bot's mind: a small state machine (patrol, notice, hunt, stalk, fight, cover, search, retreat) over shared
## senses, movement and reflexes. Each state lives in bot/ai/states; the brain only runs the current one, applies
## the one global rule (retreat to heal when low) and shows the state above the bot's head.

signal state_changed(state_name: String)

enum Alert { HIDDEN, HEARD, SEEN }

const MARKERS: Dictionary = { "notice": "!", "search": "?", "hunt": "!" }
const MARKER_COLORS: Dictionary = { "notice": Color(1.0, 0.85, 0.2), "search": Color(0.9, 0.9, 0.95),
	"hunt": Color(1.0, 0.45, 0.2) }
const SUSPICIOUS_STATES: Array[String] = ["notice", "hunt", "search", "stalk", "cover", "fight"]

var bot: Creature
var target: Creature
var woods: Woods
var senses: Perception
var mover: BotMover
var reflexes: BotReflexes
var rng := RandomNumberGenerator.new()
var state_name: String = ""
## When false the mind is paused (tests, staged stills): it still perceives, and the legs still follow mover
## commands, but no state runs.
var active: bool = true
var since_retreat: float = INF
var since_cover: float = INF
var since_spit_hit: float = INF
var _states: Dictionary = {}
var _current: BotState


func setup(bot_creature: Creature, target_creature: Creature, arena: Woods) -> void:
	bot = bot_creature
	target = target_creature
	woods = arena
	name = "BotBrain"
	rng.seed = Tuning.i("bot", "seed")
	senses = Perception.new()
	senses.setup(bot, target)
	bot.add_child(senses)
	mover = BotMover.new()
	mover.setup(bot, senses, woods)
	bot.add_child(mover)
	reflexes = BotReflexes.new(bot, target, senses, rng)
	bot.hit_taken.connect(_on_hit_taken)
	_states = {
		"patrol": PatrolState.new(self), "notice": NoticeState.new(self), "hunt": HuntState.new(self),
		"stalk": StalkState.new(self), "fight": FightState.new(self), "cover": CoverState.new(self),
		"search": SearchState.new(self), "retreat": RetreatState.new(self),
	}
	change_state("patrol")


func change_state(next: String) -> void:
	if _current != null:
		_current.exit()
	state_name = next
	_current = _states[next]
	bot.model.show_marker(MARKERS.get(next, ""), MARKER_COLORS.get(next, Color.WHITE))
	_current.enter()
	state_changed.emit(next)


## How much the bot knows about the player, for the HUD's stealth eye.
func alert() -> Alert:
	if senses.sees_target:
		return Alert.SEEN
	if senses.heard_recently() or SUSPICIOUS_STATES.has(state_name):
		return Alert.HEARD
	return Alert.HIDDEN


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
	since_spit_hit += delta
	senses.tick(delta)
	reflexes.tick()
	var next: String = _current.tick(delta)
	if next == "" and _should_retreat():
		next = "retreat"
	if next != "" and next != state_name:
		change_state(next)


func _should_retreat() -> bool:
	return state_name != "retreat" and since_retreat >= Tuning.f("bot", "retreat_cooldown") \
			and bot.health.fraction() <= Tuning.f("bot", "retreat_health_fraction")


func _on_hit_taken(_amount: float, _attacker: Creature, _ambush: bool, kind: String) -> void:
	if kind == "spit":
		since_spit_hit = 0.0


## -1 or +1 with equal odds (strafe sides, flank sides, roll sides).
static func random_side(dice: RandomNumberGenerator) -> float:
	return 1.0 if dice.randf() < 0.5 else -1.0
