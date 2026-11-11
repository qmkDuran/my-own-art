class_name SessionLog
extends Node
## One playtest session in a zone, written to playtest/sessions/<time>_<zone>.json when you leave it: time spent,
## deaths (cause and place), each boss's time to kill, and how often each skill was used.

static var writing: bool = true         ## tests turn this off before they quit

var g: Game
var _start: float
var _deaths: Array = []
var _bosses: Array = []
var _skills: Dictionary = {}
var _boss_t: float = -1.0
var _was_dead: bool = false


func setup(game: Game) -> void:
	g = game
	_start = _now()
	g.player.skills.used.connect(func(id: String) -> void: _skills[id] = int(_skills.get(id, 0)) + 1)
	g.player.life_changed.connect(_on_life)


func _process(_delta: float) -> void:
	if g.flags.has("boss") and _boss_t < 0.0:
		_boss_t = _now()
	if _boss_t >= 0.0 and g.flags.has("boss_down") and _bosses.is_empty():
		_bosses.append({"kind": String(GameData.biome["events"]["boss"]["kind"]), "seconds": snappedf(_now() - _boss_t, 0.1)})


func _on_life() -> void:
	var dead: bool = g.player.life <= 0.0
	if dead and not _was_dead:
		var at: Vector2 = g.player.global_position.round()
		_deaths.append({"cause": CombatLog.last_hit_on_player(), "at": [at.x, at.y], "level": g.player.prog.level,
			"seconds_in_zone": snappedf(_now() - _start, 0.1)})
	_was_dead = dead


func _exit_tree() -> void:
	if not writing:
		return
	var data := {"zone": g.zone_id, "seconds": snappedf(_now() - _start, 0.1), "level": g.player.prog.level,
		"deaths": _deaths, "bosses": _bosses, "skills_used": _skills}
	var f := FileAccess.open(Dev.playtest_dir("sessions").path_join("%s_%s.json" % [Dev.stamp(), g.zone_id]), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
