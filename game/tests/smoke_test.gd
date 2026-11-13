extends Node
## --smoke: loads the real town headless and checks the rules: the town and its lights are built, the shadow
## budget holds, the player walks and runs with the right clips, the townsfolk move through their routines, and
## the rain toggle wets the town; plus the graphics tiers, the tools, the UI layout, posture, the combat kit, the
## enemies and the mission (see SmokeGraphics, SmokeTools, UiLayout, PostureCheck, SmokeCombat, SmokeEnemies,
## SmokeMission). Prints SMOKE PASS or SMOKE FAIL lines, then quits.

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
	await _check_strides()
	await _check_agility()
	failures.append_array(await SmokeTools.new(m).run())
	failures.append_array(SmokeGraphics.new(m).run())
	failures.append_array(await UiLayout.new(m).run())
	failures.append_array(await PostureCheck.new(m).run())
	failures.append_array(await SmokeCombat.new(m).run())
	failures.append_array(await SmokeEnemies.new(m).run())
	failures.append_array(await SmokeMission.new(m).run())
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
	var fish: Node = m.find_child("CanalFish", true, false)
	_expect(fish != null and fish.get_child_count() > 10, "glowing fish swim in the canal")
	var outskirts: Node = m.find_child("Outskirts", true, false)
	_expect(outskirts != null and outskirts.find_children("*", "MultiMeshInstance3D", false, false).size() >= 2,
		"the outskirts have their forest rings")
	_expect(m.town.get_child_count() > 40, "town has many pieces (got %d)" % m.town.get_child_count())
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


## Feet must not slide: every character measured a sensible walk stride, and the player's walk plays at body
## speed / foot speed.
func _check_strides() -> void:
	var models: Array[CharacterModel] = [m.player.model]
	for person: Townsperson in m.townsfolk:
		models.append(person.model)
	for model: CharacterModel in models:
		var speed: float = model.foot_speed("walk")
		print("SMOKE stride %s: walk feet travel %.2f m/s" % [model.get_parent().name, speed])
		var who: String = model.get_parent().name
		_expect(speed > 0.3 and speed < 2.5, "%s has a sensible walk stride (%.2f m/s)" % [who, speed])
	_expect(m.player.model.foot_speed("run") > m.player.model.foot_speed("walk"), "the run is faster than the walk")
	await get_tree().process_frame


## The dash is a short grounded burst; the jump rises, plays the jump clip and lands again.
func _check_agility() -> void:
	m.player.global_position = Vector3(-30, 0.05, 0)
	await get_tree().create_timer(0.3).timeout
	var start: Vector3 = m.player.global_position
	m.player.dash()
	await get_tree().create_timer(0.3).timeout
	var dashed: float = Vector2(m.player.global_position.x - start.x, m.player.global_position.z - start.z).length()
	_expect(dashed > 0.6 and dashed < 2.0, "the dash is short and snappy (%.2f m)" % dashed)
	_expect(absf(m.player.global_position.y - start.y) < 0.1, "the dash stays on the ground")
	m.player.jump()
	await get_tree().create_timer(0.25).timeout
	var rise: float = m.player.global_position.y - start.y
	_expect(rise > 0.4, "the jump rises (%.2f m)" % rise)
	_expect(m.player.model.current_clip() == "jump", "the jump plays the jump clip")
	await get_tree().create_timer(1.2).timeout
	_expect(m.player.is_on_floor() and not m.player.agility.is_airborne(), "the jump lands")


func _check_rain() -> void:
	var dry: float = m.weather.wetness()
	m.weather.toggle()
	await get_tree().create_timer(1.0).timeout
	_expect(m.weather.mix > 0.0, "rain mix rises")
	_expect(m.weather.wetness() > dry, "rain wets the town")
	_expect(m.rain_fall.emitting, "rain falls")
