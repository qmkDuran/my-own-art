extends "res://tests/shots_late.gd"
## Review shots of the opening and the guidance: the practice yard's drill steps, the zone map, first-time tips,
## Help, the Esc menu, and a Tallow house with its lantern shadow on the ground.


func _opening_at(step: int) -> void:
	Session.campaign.place(Opening.QUEST, step)
	await _reenter()
	await _wait(1.0)


func _shot_yard_move() -> void:
	await _opening_at(3)
	_bot().place_player(g.event_target + Vector2(-120, 60))
	await _wait(0.6)
	await _save("yard_1_walk")


func _shot_yard_bolt() -> void:
	await _opening_at(4)
	var at: Vector2 = g.event_target
	_bot().place_player(at + Vector2(-20, 110))
	await _wait(0.6)
	_bot().cast("wickbolt", at)
	await _wait(0.12)
	await _save("yard_2_wickbolt")


func _shot_yard_flare() -> void:
	await _opening_at(6)
	_bot().place_player(g.event_target + Vector2(0, 40))
	await _wait(0.6)
	_bot().cast("flare", g.event_target)
	await _wait(0.1)
	await _save("yard_3_flare")


func _shot_gate() -> void:
	await _opening_at(8)
	await _wait(7.0)
	await _save("gate_with_marr")


func _shot_zonemap() -> void:
	Minimap.large = true
	await _wait(0.8)
	await _save("zone_map")
	Minimap.large = false


func _shot_tips() -> void:
	TutorialTips.forced = true
	g.ui.tips._want("loot")
	g.ui.tips._want("skill")
	await _wait(0.8)
	await _save("tip_loot")
	g.ui.tips.dismiss()
	await _wait(0.8)
	await _save("tip_skill")


func _shot_help() -> void:
	g.ui.open(g.ui.help)
	await _wait(0.5)
	await _save("help")


func _shot_menu() -> void:
	g.ui.set_paused(true)
	await _wait(0.5)
	await _save("esc_menu")


func _shot_house() -> void:
	var house: Vector2 = Vector2.INF
	for pr: Dictionary in g.layout.props:
		if String(pr["kind"]).begins_with("house") and (house == Vector2.INF or
				(pr["pos"] as Vector2).distance_to(g.layout.start) < house.distance_to(g.layout.start)):
			house = pr["pos"]
	g.camera.frames = []
	_bot().place_player(house + Vector2(30, 46))
	g.camera.intro(g.player.global_position, 0.0)
	g.player.light.value = 80.0
	await _wait(2.6)
	await _save("tallow_house_shadow")
