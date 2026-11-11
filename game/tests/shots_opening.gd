extends "res://tests/shots_late.gd"
## Review shots of the opening and the guidance: the practice ground's drill steps, the zone map, first-time tips,
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


## Shadows: the Lamplighter just in front of, then just behind, the nearest tall prop; one still with both.
func _shot_shadow() -> void:
	var prop: Sprite2D = null
	for n: Node in get_tree().get_nodes_in_group("tall_props"):
		var s := n as Sprite2D
		if g.layout.walkable(g.layout.cell_of(s.global_position + Vector2(0, 40))) and \
				(prop == null or s.global_position.distance_to(g.player.global_position) < prop.global_position.distance_to(g.player.global_position)):
			prop = s
	if prop == null:
		return
	g.camera.frames = []
	_bot().clear_near(100000.0)
	_bot().place_player(prop.global_position + Vector2(-34, 36))
	g.camera.intro(prop.global_position, 0.0)
	g.player.light.value = 80.0
	await _wait(2.4)
	await _save("shadow_front_" + g.zone_id)
	_bot().place_player(prop.global_position + Vector2(30, -14))
	await _wait(1.2)
	await _save("shadow_behind_" + g.zone_id)


const WALLS: Array[String] = ["glasswood", "schoolhouse"]
const BOSS_CLEAR: float = 500.0
const EDGE_ROOM: float = 420.0          ## far enough from the zone edge that the camera can centre on it
const SHADOW_KINDS: Dictionary = {"tallow": ["house_a", "house_b", "house_c"], "hollins": ["farmhouse", "house_a", "house_b"],
	"tuesday": ["house_a", "house_b", "house_c"], "schoolhouse": ["class_wall_n"], "belfry": ["pillar_a", "pillar_b"],
	"moth_hollow": ["stalagmite_b", "stalagmite_d"], "ember_road": ["farmhouse"]}


## A named object of this zone, him beside it, the camera on both: once in front of it (lower on screen) and once
## behind it (above it, so the object covers him and fades), the lantern always in his hand between.
func _shot_shadow_obj() -> void:
	var obj: Array = _shadow_object()
	if obj.is_empty():
		push_error("SHOT shadow_obj: no %s in %s" % [SHADOW_KINDS.get(g.zone_id, []), g.zone_id])
		return
	var at: Vector2 = obj[0]
	_bot().clear_near(100000.0)
	g.camera.frames = []
	g.player.light.value = 80.0
	var sides: Array = [["front", obj[1]]]
	if not WALLS.has(g.zone_id):                              # nobody stands behind a wall
		sides.append(["behind", obj[2]])
	for side: Array in sides:
		_bot().place_player(side[1])
		g.player.face(at + Vector2(0, -20))
		g.camera.intro(at + Vector2(0, -50), 10.0)                # hold the frame on the object and him
		g.camera.reset_smoothing()
		await _wait(1.6)
		await _save("shadow_%s_%s" % [g.zone_id, side[0]])


## [object position, a spot in front of it, a spot behind it], picked so both spots are open ground; away from the
## zone's edge if possible (so the camera can centre on it), else anywhere.
func _shadow_object() -> Array:
	var found: Array = _shadow_object_within(EDGE_ROOM)
	return found if not found.is_empty() else _shadow_object_within(0.0)


func _shadow_object_within(room: float) -> Array:
	if g.zone_id == "glasswood":                              # the gate wall: just south of its face
		var w := Vector2((g.layout.gate_col + 6) * g.layout.cell, g.layout.wall_rows * g.layout.cell)
		return [w, w + Vector2(-30, 40), w]
	var kinds: Array = SHADOW_KINDS.get(g.zone_id, [])
	var found: Array = []
	var things: Array = g.layout.props.duplicate()
	things.append_array(g.layout.trees)
	for pr: Dictionary in things:
		if not kinds.has(pr["kind"]):
			continue
		var pos: Vector2 = pr["pos"]
		var foot: Vector2 = ZoneLayout.footprint(String(pr["kind"]), pos).size
		var front: Vector2 = pos + (Vector2(-60.0, 40.0) if WALLS.has(g.zone_id) else Vector2(-foot.x * 0.5 + 6.0, 26.0))
		var behind: Vector2 = pos + Vector2(foot.x * 0.25, -foot.y - 22.0)
		var inside := Rect2(Vector2.ONE * room, g.layout.size_px() - Vector2.ONE * room * 2.0)
		if inside.has_point(pos) and _open(front) and (WALLS.has(g.zone_id) or _open(behind)) and \
				(g.layout.boss.is_empty() or pos.distance_to(g.layout.circle_center()) > BOSS_CLEAR):
			if found.is_empty() or pos.distance_to(g.player.global_position) < (found[0] as Vector2).distance_to(g.player.global_position):
				found = [pos, front, behind]
	return found

func _open(at: Vector2) -> bool:
	return g.layout.walkable(g.layout.cell_of(at))


## The lantern's pool on open ground with nothing else around, for the banding check: a sidecar file gives the
## pool's centre and radius on screen.
func _shot_lightpool() -> void:
	_bot().clear_near(100000.0)
	var field: Dictionary = g.layout.clearing_of_role("field")
	_bot().place_player(g.layout.center_of(field["center"]) if not field.is_empty() else g.player.global_position)
	g.camera.frames = []
	g.player.light.value = 70.0
	await _wait(2.0)
	var xf: Transform2D = get_viewport().get_canvas_transform()
	var c: Vector2 = xf * g.player.light.global_position
	var r: float = g.player.light.light_radius() * xf.get_scale().x
	await _save("lightpool")
	var f := FileAccess.open("%s/lightpool.txt" % _out, FileAccess.WRITE)
	f.store_string("%f %f %f %f" % [c.x, c.y, r, float(get_viewport().get_visible_rect().size.x)])
