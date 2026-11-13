extends Node
## --balance [--nights=N] [--stability]: the bot plays defence nights headless and reports survival time, deaths,
## kills and how each skill's picks relate to winning, flagging outliers (a skill never picked, a skill whose
## pickers win far more or less, nights far too easy or too hard). With --stability it plays shortened nights back
## to back and checks that nodes, orphan nodes, particle systems and memory stay flat (nothing piles up).

const STRATEGIES: Array[String] = ["random", "attacks_first", "passives_first", "candle_ring", "moonbeam",
	"bell_chime", "firefly_swarm", "random"]
const TOO_EASY_LEVEL: int = 40
const TOO_HARD_SECONDS: float = 120.0
const WIN_GAP: float = 0.6
const STABILITY_NIGHTS: int = 4
const STABILITY_SECONDS: float = 75.0
const NODE_TOLERANCE: int = 40
const MEMORY_GROWTH: float = 0.08
const POLL: float = 1.0

var m: Main
var bot: DefenceBot
var failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	m = Main.current
	m.night.pantry.save_path = "user://test_pantry.json"
	bot = DefenceBot.new()
	m.add_child(bot)
	if OS.get_cmdline_user_args().has("--stability"):
		await _stability()
	else:
		await _balance()
	for failure: String in failures:
		print("BALANCE FAIL ", failure)
	if failures.is_empty():
		print("BALANCE PASS")
	get_tree().quit(0 if failures.is_empty() else 1)


func _night(strategy: String) -> Dictionary:
	bot.setup(m, strategy)
	bot.picks.clear()
	m.player.global_position = Vector3(0, 0.05, 4)
	var outcome: Array = []
	m.night.ended.connect(func(won: bool, _kept: Dictionary) -> void: outcome.append(won), CONNECT_ONE_SHOT)
	m.start_night()
	while outcome.is_empty():
		await get_tree().create_timer(POLL).timeout
	return { "strategy": strategy, "won": outcome[0], "seconds": m.night.clock, "level": m.night.level,
		"kills": m.night.kills, "picks": bot.picks.duplicate() }


func _balance() -> void:
	var nights: int = int(TestRunner.arg_value("--nights=")) if TestRunner.arg_value("--nights=") != "" else 4
	var results: Array[Dictionary] = []
	for index: int in nights:
		results.append(await _night(STRATEGIES[index % STRATEGIES.size()]))
		var r: Dictionary = results[-1]
		print("BALANCE night %d (%s): %s at %.0f s, level %d, %d kills, picks %s" % [index + 1, r["strategy"],
			"WON" if r["won"] else "fainted", r["seconds"], r["level"], r["kills"], r["picks"]])
	_report_skills(results)
	_flag_difficulty(results)


func _report_skills(results: Array[Dictionary]) -> void:
	var table: Dictionary = Tuning.doc("skills")
	var skills: Array = table["attacks"].keys() + table["passives"].keys() + table["combos"].keys()
	for skill: String in skills:
		var with: Array[Dictionary] = results.filter(_picked.bind(skill, true))
		var without: Array[Dictionary] = results.filter(_picked.bind(skill, false))
		var rate_with: float = _win_rate(with)
		var rate_without: float = _win_rate(without)
		print("BALANCE skill %s: picked in %d/%d nights, win rate %.0f%% with, %.0f%% without" % [skill, with.size(),
			results.size(), rate_with * 100.0, rate_without * 100.0])
		if skill != table["starter"] and with.is_empty() and not table["combos"].has(skill):
			print("BALANCE note: %s was never picked" % skill)
		if not with.is_empty() and not without.is_empty() and absf(rate_with - rate_without) > WIN_GAP:
			print("BALANCE note: %s is an outlier (win rate %.0f%% with vs %.0f%% without)" % [skill,
				rate_with * 100.0, rate_without * 100.0])


func _flag_difficulty(results: Array[Dictionary]) -> void:
	var won: int = results.filter(_is_won).size()
	var early: int = results.filter(_fainted_early).size()
	var maxed: int = results.filter(_maxed_out).size()
	print("BALANCE summary: %d/%d nights won, %d fainted in the first 2 minutes, %d reached level %d" % [won,
		results.size(), early, maxed, TOO_EASY_LEVEL])
	if early == results.size():
		failures.append("every night was lost in the first 2 minutes (far too hard)")
	if maxed == results.size():
		failures.append("every night hit level %d (far too easy)" % TOO_EASY_LEVEL)


static func _is_won(result: Dictionary) -> bool:
	return result["won"]


static func _fainted_early(result: Dictionary) -> bool:
	return not result["won"] and float(result["seconds"]) < TOO_HARD_SECONDS


static func _maxed_out(result: Dictionary) -> bool:
	return int(result["level"]) >= TOO_EASY_LEVEL


static func _picked(result: Dictionary, skill: String, wanted: bool) -> bool:
	return (result["picks"] as Array).has(skill) == wanted


static func _win_rate(results: Array[Dictionary]) -> float:
	if results.is_empty():
		return 0.0
	return results.filter(_is_won).size() / float(results.size())


func _stability() -> void:
	var samples: Array[Dictionary] = []
	for index: int in STABILITY_NIGHTS:
		m.night.length = STABILITY_SECONDS
		m.night.boss_at = STABILITY_SECONDS * 0.5
		await _night("random")
		await get_tree().create_timer(POLL).timeout
		samples.append(_sample())
		print("BALANCE stability after night %d: %s" % [index + 1, samples[-1]])
	var first: Dictionary = samples[1]
	var last: Dictionary = samples[-1]
	if int(last["nodes"]) - int(first["nodes"]) > NODE_TOLERANCE:
		failures.append("nodes pile up: %d after night 2, %d after the last" % [first["nodes"], last["nodes"]])
	if int(last["orphans"]) > int(first["orphans"]):
		failures.append("orphan nodes pile up: %d to %d" % [first["orphans"], last["orphans"]])
	if int(last["particles"]) > int(first["particles"]):
		failures.append("particle systems pile up: %d to %d" % [first["particles"], last["particles"]])
	if float(last["memory"]) > float(first["memory"]) * (1.0 + MEMORY_GROWTH):
		failures.append("memory grows: %.1f MB to %.1f MB" % [first["memory"], last["memory"]])


func _sample() -> Dictionary:
	return { "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"particles": m.find_children("*", "GPUParticles3D", true, false).size(),
		"memory": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0 }
