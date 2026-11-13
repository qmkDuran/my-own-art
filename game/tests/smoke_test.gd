extends Node
## --smoke: loads the real town headless and checks the rules: the town and its lights are built, the shadow
## budget holds, the player walks and runs with the right clips, the townsfolk move through their routines, and
## the rain toggle wets the town; plus the graphics tiers and the defence night (see SmokeGraphics,
## SmokeDefence). Prints SMOKE PASS or SMOKE FAIL lines, then quits.

var m: Main
var failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.5).timeout
	m = Main.current
	_check_town()
	await _check_player()
	await _check_townsfolk()
	await _check_rain()
	failures.append_array(SmokeGraphics.new(m).run())
	failures.append_array(await SmokeDefence.new(m).run())
	failures.append_array(await UiLayout.new(m).run())
	for failure: String in failures:
		print("SMOKE FAIL ", failure)
	if failures.is_empty():
		print("SMOKE PASS")
	get_tree().quit(0 if failures.is_empty() else 1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _check_town() -> void:
	_expect(m.town.lamps.size() >= 15, "at least 15 lamps (got %d)" % m.town.lamps.size())
	_expect(m.town.lights.size() > m.town.lamps.size(), "windows add lights")
	_expect(m.town.fountain != null, "fountain placed")
	_expect(m.town.get_child_count() > 60, "town has many pieces (got %d)" % m.town.get_child_count())
	m.budget.refresh()
	_expect(m.budget.shadowed_count() <= Tuning.i_look("budget", "shadowed_lights"), "shadow budget holds")


func _check_player() -> void:
	var start: Vector3 = m.player.global_position
	m.controller.enabled = false
	m.player.wish = Vector3.FORWARD
	await get_tree().create_timer(1.0).timeout
	_expect(m.player.model.current_clip() == "walk", "walking plays walk (got %s)" % m.player.model.current_clip())
	_expect(m.player.global_position.distance_to(start) > 1.0, "player walked")
	m.player.running = true
	await get_tree().create_timer(0.8).timeout
	_expect(m.player.model.current_clip() == "run", "running plays run")
	m.player.wish = Vector3.ZERO
	m.player.running = false
	await get_tree().create_timer(1.0).timeout
	_expect(m.player.model.current_clip() == "idle", "standing plays idle")
	_expect(m.player.global_position.y > -0.2, "player stays on the ground")


func _check_townsfolk() -> void:
	_expect(m.townsfolk.size() >= 3, "three townsfolk")
	var child: Townsperson = m.townsfolk[2]
	var before: Vector3 = child.position
	await get_tree().create_timer(2.0).timeout
	_expect(child.position.distance_to(before) > 0.5, "the child walks her routine")
	_expect(m.townsfolk[1].model.current_clip() == "sit", "the old man sits on his bench")


func _check_rain() -> void:
	var dry: float = m.weather.wetness()
	m.weather.toggle()
	await get_tree().create_timer(1.0).timeout
	_expect(m.weather.mix > 0.0, "rain mix rises")
	_expect(m.weather.wetness() > dry, "rain wets the town")
	_expect(m.rain_fall.emitting, "rain falls")
