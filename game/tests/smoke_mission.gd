class_name SmokeMission
extends RefCounted
## Smoke checks of the mission and the music: walking through the gate starts the mission; each encounter starts
## at its trigger, brings its waves and, once beaten, relights its lanterns; the boss's ring closes while he is
## fought; beating him completes the mission and a fade carries the Lamplighter home, where everything resets. The
## music follows (town, explore, combat, boss) and crossfades smoothly, and every music and sound level is sane.

const STEP_SECONDS: float = 0.3
const KILL: float = 100000.0

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	m.controller.enabled = false
	m.kit_input.enabled = false
	_check_levels()
	await _walk_in()
	for encounter: Encounter in m.mission.encounters:
		await _fight(encounter)
	await _come_home()
	return failures


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _go(at: Array) -> void:
	m.player.global_position = Tuning.point(at.slice(0, 2)) + Vector3.UP * 0.1
	await m.get_tree().create_timer(STEP_SECONDS).timeout


func _walk_in() -> void:
	m.player.global_position = Tuning.point(Tuning.doc("mission")["gate"]["home"])
	await m.get_tree().create_timer(float(Tuning.doc("music")["crossfade_seconds"]) + STEP_SECONDS).timeout
	_expect(m.mission.state == Mission.State.IDLE and m.music.state == "town",
		"in town the mission waits and the town theme plays")
	await _go(Tuning.doc("mission")["gate"]["trigger"])
	_expect(m.mission.state == Mission.State.ACTIVE, "walking through the gate starts the mission")
	_expect(m.music.state == "explore", "the exploring track plays in the woods (%s)" % m.music.state)
	await _crossfade("explore", "town")


## A crossfade: part-way through, both tracks are partly up; after the crossfade time, only the new one.
func _crossfade(to: String, from: String) -> void:
	var seconds: float = float(Tuning.doc("music")["crossfade_seconds"])
	await m.get_tree().create_timer(seconds * 0.4).timeout
	var middle: Dictionary = m.music.levels()
	_expect(float(middle[to]) > 0.1 and float(middle[to]) < 0.9 and float(middle[from]) > 0.1,
		"the music crossfades from %s to %s (part-way %s)" % [from, to, middle])
	await m.get_tree().create_timer(seconds * 0.8).timeout
	var after: Dictionary = m.music.levels()
	_expect(is_equal_approx(float(after[to]), 1.0) and float(after[from]) == 0.0,
		"the crossfade to %s ends cleanly %s" % [to, after])


func _fight(encounter: Encounter) -> void:
	await _go(encounter.spec["trigger"])
	_expect(encounter.started and not m.roster.enemies.is_empty(), "%s starts at its trigger" % encounter.id)
	var wanted: String = "boss" if encounter.is_boss() else "combat"
	_expect(m.music.state == wanted, "%s plays the %s music (%s)" % [encounter.id, wanted, m.music.state])
	if encounter.is_boss():
		_expect(m.mission.barrier.closed, "the boss's ring closes")
	var waves: int = 0
	while not encounter.cleared:
		waves = maxi(waves, encounter.wave + 1)
		for enemy: Enemy in m.roster.enemies.duplicate():
			enemy.invulnerable = false
			enemy.take_hit(Hit.new(KILL, "heavy", enemy.centre()))
			enemy.take_hit(Hit.new(KILL, "heavy", enemy.centre()))
		await m.get_tree().create_timer(STEP_SECONDS).timeout
	_expect(waves == (encounter.spec["waves"] as Array).size(), "%s brings all its waves (%d)" % [encounter.id, waves])
	for lamp: LampLight in m.woods.lamps_of.get(encounter.id, []):
		_expect(lamp.lit, "clearing %s relights its lanterns" % encounter.id)


func _come_home() -> void:
	_expect(m.mission.state == Mission.State.COMPLETE, "beating the boss completes the mission")
	_expect(not m.mission.barrier.closed, "the ring opens again")
	await m.get_tree().create_timer(Tuning.number("mission", "flow", "home_delay") + Tuning.number("mission",
		"flow", "fade_seconds") * 2.0 + STEP_SECONDS).timeout
	var home: Vector3 = Tuning.point(Tuning.doc("mission")["gate"]["home"])
	_expect(m.mission.state == Mission.State.IDLE, "the mission resets after coming home")
	_expect(Vector2(m.player.global_position.x - home.x, m.player.global_position.z - home.z).length() < 1.0,
		"the Lamplighter is carried home to the gate")
	_expect(m.roster.enemies.is_empty(), "the woods are empty again")
	var lit: int = 0
	for lamps: Array in m.woods.lamps_of.values():
		lit += lamps.filter(func(lamp: LampLight) -> bool: return lamp.lit).size()
	_expect(lit == 0, "the woods' lanterns go dark again for the next try")


## Music and sound levels stay in a sane range (no track or cue blasting, none inaudible).
func _check_levels() -> void:
	var limits: Dictionary = Tuning.doc("music")["limits"]
	for track: String in Tuning.doc("music")["tracks"]:
		var level: float = m.music.full_db(track)
		_expect(level <= float(limits["music_max_db"]) and level >= float(limits["music_min_db"]),
			"the %s music level %.0f dB is sane" % [track, level])
	for level: float in SfxPlayer.cue_levels():
		_expect(level <= float(limits["sfx_max_db"]) and level >= float(limits["sfx_min_db"]),
			"a sound cue level %.0f dB is sane" % level)
	for sound: String in Tuning.doc("audio")["files"]:
		_expect(m.vfx.sfx.stream(sound) != null, "the sound file %s loads" % sound)
