class_name Mission
extends Node
## The Gloomwood mission's flow: walking through the town gate starts it (a title banner, the objective); each
## encounter fights in turn and clearing one relights its lanterns; the Gloom King's ring closes while he is fought;
## beating him completes the mission, and after a moment a soft fade carries the Lamplighter home to the town side
## of the gate. Fainting fails it the same gentle way, and everything resets for another try. Also picks the music:
## the town theme in town, the exploring track in the woods, the combat track while a fight is on.

signal banner(text: String, seconds: float)
signal objective_changed(text: String)
signal travelling(seconds: float)
signal state_changed(state: State)

enum State { IDLE, ACTIVE, COMPLETE, FAILED }

var state: State = State.IDLE
var encounters: Array[Encounter] = []
var barrier: ArenaBarrier
var _roster: Roster
var _player: Player
var _health: PlayerHealth
var _decor: MissionDecor
var _music: MusicDirector
var _timer: float = 0.0


func setup(roster: Roster, player: Player, health: PlayerHealth, decor: MissionDecor, music: MusicDirector) -> void:
	name = "Mission"
	_roster = roster
	_player = player
	_health = health
	_decor = decor
	_music = music
	barrier = ArenaBarrier.new()
	barrier.name = "ArenaBarrier"
	add_child(barrier)
	health.fainted.connect(fail)
	_reset_encounters()


func _reset_encounters() -> void:
	encounters.clear()
	for spec: Dictionary in Tuning.doc("mission")["encounters"]:
		encounters.append(Encounter.new(spec))
	for lamps: Array in _decor.lamps_of.values():
		for lamp: LampLight in lamps:
			lamp.snuff()


func start() -> void:
	if state != State.IDLE:
		return
	_set_state(State.ACTIVE)
	_reset_encounters()
	var spec: Dictionary = Tuning.doc("mission")
	banner.emit("%s\n%s" % [spec["title"], spec["objective"]], _flow("banner_seconds"))
	objective_changed.emit(spec["objective"])
	_roster.cue("mission", _player.global_position)


func complete() -> void:
	if state != State.ACTIVE:
		return
	_set_state(State.COMPLETE)
	barrier.open()
	_timer = _flow("home_delay")
	banner.emit("Mission complete!\nThe Gloomwood glows again.", _flow("banner_seconds"))
	objective_changed.emit("")
	_roster.cue("mission", _player.global_position)


func fail() -> void:
	if state != State.ACTIVE:
		return
	_set_state(State.FAILED)
	_timer = Tuning.number("combat", "player", "faint_seconds")
	banner.emit("You faint... your lantern carries you home.", _flow("banner_seconds"))


## Back to the town side of the gate with a soft fade; the woods reset for another try.
func go_home() -> void:
	var fade: float = _flow("fade_seconds")
	travelling.emit(fade)
	await get_tree().create_timer(fade, false).timeout
	var gate: Dictionary = Tuning.doc("mission")["gate"]
	_player.global_position = Tuning.point(gate["home"])
	_player.yaw = deg_to_rad(float(gate["home_yaw_deg"]))
	_player.rotation.y = _player.yaw
	_roster.clear()
	barrier.open()
	_reset_encounters()
	_health.reset()
	objective_changed.emit("")
	_set_state(State.IDLE)


func _set_state(next: State) -> void:
	state = next
	state_changed.emit(state)


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			if _in_circle(Tuning.doc("mission")["gate"]["trigger"]):
				start()
		State.ACTIVE:
			_advance()
		_:
			_timer -= delta
			if _timer <= 0.0 and _timer > -delta:
				go_home()
	_music.set_state(music_state())


func _advance() -> void:
	for encounter: Encounter in encounters:
		var event: String = encounter.update(_player.global_position, _roster)
		if event == "started" and encounter.is_boss():
			barrier.close()
			banner.emit("The Gloom King!", _flow("clear_banner_seconds"))
		elif event == "cleared":
			_on_cleared(encounter)


func _on_cleared(encounter: Encounter) -> void:
	for lamp: LampLight in _decor.lamps_of.get(encounter.id, []):
		lamp.relight()
	if encounter.is_boss():
		complete()
	else:
		banner.emit("Cleared! The lanterns light up.", _flow("clear_banner_seconds"))


## The music for now: boss, combat, explore (in the woods) or town.
func music_state() -> String:
	for encounter: Encounter in encounters:
		if encounter.engaged():
			return "boss" if encounter.is_boss() else "combat"
	return "explore" if state == State.ACTIVE or in_woods() else "town"


func in_woods() -> bool:
	var rect: Array = Tuning.doc("mission")["floor"]
	var at: Vector3 = _player.global_position
	return at.x >= float(rect[0]) and at.x <= float(rect[2]) and at.z >= float(rect[1]) and at.z <= float(rect[3])


func _in_circle(circle: Array) -> bool:
	var at: Vector3 = _player.global_position
	return Vector2(at.x - float(circle[0]), at.z - float(circle[1])).length() < float(circle[2])


func _flow(key: String) -> float:
	return Tuning.number("mission", "flow", key)
