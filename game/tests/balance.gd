extends Node
## --balance (with --zone=<id>): the DemoBot plays the zone the way a player would at its intended level (the
## middle of the zone's level range, rare gear of that level, points spent): walks to the nearest packs one after
## another and fights them, then fights the boss at the top of the range. Prints one BALANCE line per fight and a
## summary (time to kill, life lost, tonics used, deaths) for the notes table.

const PACKS: int = 8
const PACK_RADIUS: float = 400.0
const STRAGGLER_RANGE: float = 480.0     # beyond the bot's sight: it walks over
const APPROACH: float = 220.0            # arrives this far from the straggler
const PACK_TIMEOUT: float = 30.0
const BOSS_TIMEOUT: float = 150.0
var g: Game
var _deaths: int = 0


func _ready() -> void:
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, false).timeout


func _run() -> void:
	while Game.current == null:
		await get_tree().process_frame
	await _wait(1.0)
	g = Game.current
	g.player.died_and_rose.connect(func() -> void: _deaths += 1)
	add_child(DemoBot.new())
	var lv: Array = GameData.zone(g.zone_id)["level"]
	_build(int((int(lv[0]) + int(lv[1])) / 2))
	var rows: Array = []
	for c: Vector2 in _pack_centres():
		rows.append(await _fight(c, PACK_TIMEOUT, "pack"))
	var packs: String = _summary(rows)
	var boss: String = "no boss"
	if not g.layout.boss.is_empty():
		_build(int(lv[1]))
		boss = await _boss()
	print("BALANCE %s level %d: packs %s | boss %s" % [g.zone_id, int((int(lv[0]) + int(lv[1])) / 2), packs, boss])
	get_tree().quit()


## A player of this level (see ShotHelper.player_build).
func _build(level: int) -> void:
	ShotHelper.new(g).player_build(level)

func _pack_centres() -> Array[Vector2]:
	var seen: Dictionary = {}
	var out: Array[Vector2] = []
	var spawns: Array = g.layout.spawns.duplicate()
	spawns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["level_progress"]) < float(b["level_progress"]))
	for s: Dictionary in spawns:
		if not seen.has(int(s["pack"])) and out.size() < PACKS:
			seen[int(s["pack"])] = true
			out.append(s["pos"])
	return out


## Walk up to a pack (placed just outside its reach, as a player arriving on foot), fight until it is gone.
func _fight(at: Vector2, timeout: float, kind: String) -> Dictionary:
	var h := ShotHelper.new(g)
	h.place_player(at + Vector2(-220, 60))
	g.player.light.value = float(GameData.light["start"])
	var life0: float = g.player.life
	var tonics0: int = g.player.tonics
	var deaths0: int = _deaths
	var t: float = 0.0
	await _wait(0.2)
	while t < timeout and _foes_near(at) > 0:
		await _wait(0.25)
		t += 0.25
		_close_in(at, h)
	var row := {"kind": kind, "time": t, "lost": maxf(0.0, life0 - g.player.life) / g.player.stats.max_life(),
		"tonics": tonics0 - g.player.tonics, "deaths": _deaths - deaths0, "timeout": t >= timeout}
	print("BALANCE fight %s %.1f s, life lost %d%%, tonics %d, deaths %d%s" % [kind, t, roundi(row["lost"] * 100.0), row["tonics"],
		row["deaths"], " (timed out)" if row["timeout"] else ""])
	g.player.life = g.player.stats.max_life()
	g.player.refill_tonics()
	return row


## A straggler the bot cannot see (scattered or rewound to its post) is walked up to, as a player would.
func _close_in(at: Vector2, h: ShotHelper) -> void:
	var near: Array = get_tree().get_nodes_in_group("enemies").filter(func(n: Node) -> bool:
		return (n as Enemy).global_position.distance_to(at) < PACK_RADIUS)
	if near.is_empty():
		return
	var me: Vector2 = g.player.global_position
	near.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.global_position.distance_to(me) < b.global_position.distance_to(me))
	var foe := near[0] as Enemy
	if foe.global_position.distance_to(me) > STRAGGLER_RANGE:
		h.place_player(foe.global_position + (me - foe.global_position).normalized() * APPROACH)


func _foes_near(at: Vector2) -> int:
	return get_tree().get_nodes_in_group("enemies").filter(func(n: Node) -> bool:
		return (n as Enemy).global_position.distance_to(at) < PACK_RADIUS).size()


func _boss() -> String:
	ShotHelper.new(g).clear_near(100000.0)
	g.player.global_position = g.layout.free_spot_near(g.layout.circle_center() + Vector2(0, 120), g.player.radius)
	g.camera.reset_smoothing()
	g.start_boss()
	var deaths0: int = _deaths
	var t: float = 0.0
	var tonics_used: int = 0
	var last_tonics: int = g.player.tonics
	while t < BOSS_TIMEOUT and is_instance_valid(g.spawner.boss) and not g.spawner.boss.dead:
		await _wait(0.25)
		t += 0.25
		if g.player.tonics < last_tonics:
			tonics_used += last_tonics - g.player.tonics
		last_tonics = g.player.tonics
		if g.player.global_position.distance_to(g.layout.circle_center()) > 600.0:      # woke at a lamp: walk back in
			g.player.global_position = g.layout.free_spot_near(g.layout.circle_center() + Vector2(0, 120), g.player.radius)
	var done: bool = not is_instance_valid(g.spawner.boss) or g.spawner.boss.dead
	return "%s in %.0f s, tonics %d, deaths %d" % ["killed" if done else "NOT killed", t, tonics_used, _deaths - deaths0]


func _summary(rows: Array) -> String:
	var t: float = 0.0
	var lost: float = 0.0
	var deaths: int = 0
	var to: int = 0
	for r: Dictionary in rows:
		t += float(r["time"])
		lost += float(r["lost"])
		deaths += int(r["deaths"])
		to += 1 if r["timeout"] else 0
	var n: float = maxf(1.0, rows.size())
	return "avg clear %.1f s, avg life lost %d%%, deaths %d, timeouts %d of %d" % [t / n, roundi(lost / n * 100.0), deaths, to, rows.size()]

