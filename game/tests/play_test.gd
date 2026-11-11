extends Node
## Plays the opening with real key presses (no fast mode): title, New Game, the story cards, choosing a
## companion, then the field menu opening and closing, walking into Gran's cottage and talking to her.

var _fails: PackedStringArray = []


func _ready() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.path))
	await _secs(0.5)
	TestRunner.main().show_title()
	await _secs(0.3)
	_press("accept")
	await _mash_until(func() -> bool: return not Game.party.is_empty(), 30.0)
	_check(Game.party.size() == 1, "companion chosen with key presses")
	await _mash_until(func() -> bool: return _world() != null and not _world().busy, 15.0)
	_check(_world() != null, "overworld reached")
	await _menu_round_trip()
	await _visit_gran()
	await _click_walk()
	print("PLAY %s%s" % ["PASS" if _fails.is_empty() else "FAIL: ", ", ".join(_fails)])
	get_tree().quit(0 if _fails.is_empty() else 1)


func _world() -> Overworld:
	for c: Node in TestRunner.main().get_children():
		if c is Overworld:
			return c
	return null


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _press(action: String, hold: float = 0.05) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await _secs(hold)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _secs(0.05)


func _mash_until(done: Callable, limit: float) -> void:
	var t: float = 0.0
	while not done.call() and t < limit:
		await _press("accept")
		await _secs(0.15)
		t += 0.25


func _menu_round_trip() -> void:
	var w: Overworld = _world()
	await _press("menu")
	await _secs(0.3)
	_check(w.busy, "Esc opens the field menu")
	await _press("cancel")
	await _secs(0.4)
	_check(not w.busy, "cancel closes the field menu and does not reopen it")


func _walk(dir: String, steps: int) -> void:
	for i: int in steps:
		await _press(dir, 0.21)
		await _secs(0.05)


func _visit_gran() -> void:
	var w: Overworld = _world()
	await _walk("move_left", 9)
	await _walk("move_up", 3)
	await _secs(0.8)
	_check(w.map.id == "home", "walked through Gran's door (at %s %s)" % [w.map.id, w.player.cell])
	await _walk("move_right", 2)
	await _walk("move_up", 3)
	await _mash_until(func() -> bool: return Game.flags.get("met_gran", false), 20.0)
	_check(Game.flags.get("met_gran", false), "talked to Gran with the accept key")


## Click a floor cell in the cottage: the player walks there by itself.
func _click_walk() -> void:
	var w: Overworld = _world()
	var target := Vector2i(2, 6)
	await w.clicks.go(target)
	_check(w.player.cell == target, "click-to-walk reached the clicked cell (at %s)" % w.player.cell)
