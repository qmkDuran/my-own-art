class_name MatchFlow
extends Node
## The match around the fight: start screen, playing, paused (Esc frees the mouse), won or lost, and restart (R).
## On the start and pause screens 1 / 2 / 3 pick Easy / Normal / Hard. Everything but the HUD and this node is
## paused outside of play.

signal phase_changed(phase: Phase)

enum Phase { INTRO, PLAYING, PAUSED, WON, LOST }

var phase: Phase = Phase.INTRO
var _player: Creature


func setup(player: Creature, bot: Creature) -> void:
	_player = player
	name = "MatchFlow"
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.died.connect(_on_died)
	bot.died.connect(_on_died)


func begin(show_intro: bool) -> void:
	_enter(Phase.INTRO if show_intro else Phase.PLAYING)


func play() -> void:
	_enter(Phase.PLAYING)


func restart() -> void:
	Main.skip_intro = true
	get_tree().paused = false
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and phase != Phase.INTRO:
		restart()
	elif event.is_action_pressed("pause") and phase == Phase.PLAYING:
		_enter(Phase.PAUSED)
	elif phase == Phase.PAUSED and (event.is_action_pressed("pause") or _is_click(event)):
		play()
	elif phase == Phase.INTRO and (event.is_action_pressed("start") or _is_click(event)):
		play()
	elif phase == Phase.INTRO or phase == Phase.PAUSED:
		_pick_difficulty(event)


func _pick_difficulty(event: InputEvent) -> void:
	for level: String in Difficulty.LEVELS:
		if event.is_action_pressed("difficulty_" + level):
			Difficulty.level = level
			phase_changed.emit(phase)


func _enter(next: Phase) -> void:
	phase = next
	get_tree().paused = next != Phase.PLAYING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if next == Phase.PLAYING else Input.MOUSE_MODE_VISIBLE
	phase_changed.emit(next)


func _on_died(creature: Creature) -> void:
	if phase == Phase.PLAYING:
		_enter(Phase.LOST if creature == _player else Phase.WON)


## A released click, so the click that starts or resumes the game is not also a bite.
static func _is_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and not (event as InputEventMouseButton).pressed
