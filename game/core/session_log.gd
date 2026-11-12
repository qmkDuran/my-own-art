class_name SessionLog
extends Node
## One fight's playtest log, written as JSON when the fight ends (win or lose) or is restarted or closed: the
## player's position trail, hide events, attacks started and hits landed by both sides, the bot's states and
## decisions (with the top scores), the outcome and the duration. Files go to playtest/sessions/ next to the game
## folder (user://sessions when that is not writable). tools/analyze_session.py summarises one.

const TOP_SCORES: int = 3
const PRECISION: float = 0.1
const SCORE_PRECISION: float = 0.01

## Where logs go; empty means the default folder. Tests point this at a scratch folder.
static var directory: String = ""

var written_path: String = ""
var _main: Main
var _clock: float = 0.0
var _trail_left: float = 0.0
var _trail: Array = []
var _events: Array = []
var _decisions: Array = []
var _last_option: String = ""
var _spot: HidingSpot
var _winding: Dictionary = {}


func setup(match_root: Main) -> void:
	_main = match_root
	name = "SessionLog"
	match_root.player.hit_taken.connect(_on_hit.bind("player"))
	match_root.bot.hit_taken.connect(_on_hit.bind("bot"))
	match_root.brain.state_changed.connect(func(state: String) -> void: _event("bot_state", { "state": state }))
	match_root.brain.decided.connect(_on_decided)
	match_root.flow.phase_changed.connect(_on_phase)
	tree_exiting.connect(func() -> void: write("unfinished"))


func _physics_process(delta: float) -> void:
	_clock += delta
	_trail_left -= delta
	if _trail_left <= 0.0:
		_trail_left = Tuning.ai_f("session", "trail_interval")
		var at: Vector3 = _main.player.global_position
		_trail.append([snappedf(_clock, PRECISION), snappedf(at.x, PRECISION), snappedf(at.z, PRECISION)])
	_watch_hiding()
	_watch_attacks(_main.player, "player")
	_watch_attacks(_main.bot, "bot")


## Writes the log once; returns its path ("" if it could not be written).
func write(outcome: String) -> String:
	if written_path != "":
		return written_path
	var folder: String = _folder()
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	var path: String = folder.path_join("%s_%s.json" % [stamp, outcome])
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(_record(outcome), "  "))
	written_path = path
	return path


func _record(outcome: String) -> Dictionary:
	return { "outcome": outcome, "duration": snappedf(_clock, PRECISION), "difficulty": Difficulty.level,
		"trail": _trail, "events": _events, "decisions": _decisions,
		"final_life": { "player": _main.player.health.current, "bot": _main.bot.health.current } }


func _folder() -> String:
	var folder: String = directory
	if folder == "":
		folder = ProjectSettings.globalize_path("res://").path_join("../playtest/sessions").simplify_path()
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		folder = ProjectSettings.globalize_path("user://sessions")
		DirAccess.make_dir_recursive_absolute(folder)
	return folder


func _event(kind: String, details: Dictionary) -> void:
	details["t"] = snappedf(_clock, PRECISION)
	details["kind"] = kind
	_events.append(details)


func _watch_hiding() -> void:
	var spot: HidingSpot = _main.player.stealth.current_spot()
	if spot == _spot:
		return
	if spot != null:
		_event("hide", { "spot": spot.spot_id, "type": spot.kind })
	else:
		_event("leave_cover", { "spot": _spot.spot_id })
	_spot = spot


func _watch_attacks(creature: Creature, who: String) -> void:
	for move: String in ["bite", "spit", "dodge", "trap"]:
		var ability: Ability = creature.get(move)
		var started: bool = ability.busy()
		if started and not _winding.get(who + move, false):
			_event("move", { "by": who, "move": move, "ambush_ready": creature.ambush_ready() })
		_winding[who + move] = started


func _on_hit(amount: float, attacker: Creature, ambush: bool, kind: String, victim: String) -> void:
	var by: String = "player" if attacker == _main.player else "bot"
	_event("hit", { "by": by, "on": victim, "move": kind, "damage": snappedf(amount, PRECISION), "ambush": ambush })


func _on_decided(option: String, scores: Dictionary) -> void:
	if option == _last_option:
		return
	_last_option = option
	var ranked: Array = scores.keys()
	ranked.sort_custom(func(a: String, b: String) -> bool: return scores[a] > scores[b])
	var top: Dictionary = {}
	for key: String in ranked.slice(0, TOP_SCORES):
		top[key] = snappedf(float(scores[key]), SCORE_PRECISION)
	_decisions.append({ "t": snappedf(_clock, PRECISION), "option": option, "top": top })


func _on_phase(phase: MatchFlow.Phase) -> void:
	if phase == MatchFlow.Phase.WON or phase == MatchFlow.Phase.LOST:
		write("won" if phase == MatchFlow.Phase.WON else "lost")
