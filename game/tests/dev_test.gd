extends Node
## --devtest (run with --dev): the playtest tools work: god mode, one-hit kills, level presets, spawning, the boss
## restart, a feedback note with its screenshot, and the session log written when the zone is left.

var _fails: Array[String] = []
var _count: int = 0


func _ready() -> void:
	_run.call_deferred()


func expect(ok: bool, what: String) -> void:
	_count += 1
	if not ok:
		_fails.append(what)
	print("DEV %s: %s" % ["ok" if ok else "FAIL", what])


func _run() -> void:
	while Game.current == null:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var g: Game = Game.current
	var tools: DevTools = g.get_children().filter(func(n: Node) -> bool: return n is DevTools).front()
	expect(tools != null, "the dev tools are in the game")
	var menu: DevMenu = tools.get_children().filter(func(n: Node) -> bool: return n is DevMenu).front()
	menu._set_level(20)
	expect(g.player.prog.level == 20, "the level preset sets level 20")
	Dev.god = true
	var life: float = g.player.life
	Combat.hit_player(null, 50.0, "blunt", g.player.global_position)
	expect(g.player.life == life, "god mode: no damage")
	Dev.god = false
	var n0: int = get_tree().get_nodes_in_group("enemies").size()
	menu._spawn()
	expect(get_tree().get_nodes_in_group("enemies").size() == n0 + DevMenu.PACK_SIZE, "a pack spawns")
	Dev.one_hit = true
	var e: Enemy = get_tree().get_nodes_in_group("enemies").back()
	Combat.hit_enemy(e, 1.0)
	expect(e.dead, "one-hit kills")
	Dev.one_hit = false
	var fb: FeedbackBox = tools.get_children().filter(func(n: Node) -> bool: return n is FeedbackBox).front()
	fb.open()
	var before: int = DirAccess.get_files_at(Dev.playtest_dir("notes")).size()
	fb._save("devtest note")
	var made: int = 2 if DisplayServer.get_name() != "headless" else 1
	expect(DirAccess.get_files_at(Dev.playtest_dir("notes")).size() == before + made and not get_tree().paused,
		"F8 saves a note and its screenshot, and unpauses")
	_cleanup("notes")
	var sessions: int = DirAccess.get_files_at(Dev.playtest_dir("sessions")).size()
	Session.travel(g, "tallow")
	await get_tree().create_timer(1.0).timeout
	expect(DirAccess.get_files_at(Dev.playtest_dir("sessions")).size() > sessions, "leaving a zone writes the session log")
	_cleanup("sessions")
	SessionLog.writing = false
	print("DEV %s (%d checks, %d failed)" % ["PASS" if _fails.is_empty() else "FAIL", _count, _fails.size()])
	get_tree().quit()


## The test's own files are not playtest data.
func _cleanup(sub: String) -> void:
	var dir: String = Dev.playtest_dir(sub)
	for f: String in DirAccess.get_files_at(dir):
		if FileAccess.get_modified_time(dir.path_join(f)) >= int(Time.get_unix_time_from_system()) - 60:
			DirAccess.remove_absolute(dir.path_join(f))
