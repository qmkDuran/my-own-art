class_name ShotHelper
extends RefCounted
## Shortcuts for scripted test scenes (screenshots, smoke test, demo): level the character, place a pack, use a
## skill regardless of cooldown, spend points, fill the bag, point the mouse at something, show the whole zone.

const OVERVIEW_DARK := Color(0.55, 0.55, 0.62)

var g: Game


func _init(game: Game) -> void:
	g = game


func level_up(to: int) -> void:
	var p: Progression = g.player.prog
	while p.level < to:
		p.add_xp(p.xp_to_next() - p.xp + 1.0)
	g.player.refresh_stats()
	g.player.life = g.player.stats.max_life()
	g.player.oil = g.player.stats.max_oil()


func clear_near(r: float) -> void:
	for n: Node in g.get_tree().get_nodes_in_group("enemies"):
		if (n as Node2D).global_position.distance_to(g.player.global_position) < r:
			n.queue_free()


func pack_near(kinds: Array, offset: Vector2) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var base: Vector2 = g.player.global_position + offset
	for i: int in kinds.size():
		var at: Vector2 = base + Vector2(cos(i * 1.7), sin(i * 1.7)) * (24.0 + i * 12.0)
		at = g.layout.free_spot_near(at, float(GameData.enemy(String(kinds[i]))["radius"]))
		var e: Enemy = g.spawner.spawn(String(kinds[i]), at, "normal", [], 3)
		e.wake()
		out.append(e)
	return out


## Puts the Lamplighter at a free spot near p (never inside a prop) and snaps the camera.
func place_player(p: Vector2) -> void:
	g.player.global_position = g.layout.free_spot_near(p, g.player.radius)
	g.camera.reset_smoothing()


func cast(id: String, at: Vector2) -> bool:
	g.player.skills.cooldowns[id] = 0.0
	g.player.busy_t = 0.0
	g.player.oil = g.player.stats.max_oil()
	return g.player.skills.try_use(id, at)


func spec(skill: String, nodes: Array) -> void:
	var p: Progression = g.player.prog
	if not p.is_specialised(skill):
		if p.specialised.size() >= p.spec_slots():
			p.forget(String(p.specialised[p.specialised.size() - 1]))
		p.specialised.append(skill)
	p.skills[skill]["level"] = maxi(int(p.skills[skill]["level"]), nodes.size() + 2)
	for n: String in nodes:
		p.add_spec(skill, n)


func fill_bag() -> void:
	var lv: int = g.player.prog.level
	g.player.inv.add(LootGen.make(lv, "rare"))
	g.player.inv.add(LootGen.make_unique("long_night", lv))
	g.player.inv.add(LootGen.make(lv, "magic"))
	g.player.inv.add(LootGen.make(lv, "set"))
	g.player.inv.add(LootGen.make(lv, "normal"))
	g.player.inv.add(LootGen.make_unique("moth_mother", lv))
	g.player.inv.equipped["staff"] = _staff(lv)
	g.player.inv.changed.emit()


## A magic lantern staff to wear (so bag staves show a comparison).
func _staff(lv: int) -> Dictionary:
	var it: Dictionary = LootGen.make_from_base(LootGen.base_by_id("wickpole"), lv, "magic")
	LootGen.add_affixes(it, 2, lv)
	it["name"] = LootGen.item_name(it, LootGen.base_by_id("wickpole"))
	return it


## What a player would be wearing by this level: a rare staff, coat and relic of the right level.
func gear_up(lv: int) -> void:
	for slot: String in ["staff", "body", "relic"]:
		var bases: Array = GameData.items["bases"].filter(func(b: Dictionary) -> bool: return b["slot"] == slot and int(b["level"]) <= lv)
		var base: Dictionary = bases[bases.size() - 1]
		var it: Dictionary = LootGen.make_from_base(base, lv, "rare")
		LootGen.add_affixes(it, 4, lv)
		it["name"] = LootGen.item_name(it, base)
		g.player.inv.equipped[slot] = it
	g.player.inv.changed.emit()


## Moves the mouse (screen-space UI coordinates) so hover tooltips appear.
func hover(ui_pos: Vector2) -> void:
	var screen: Vector2 = g.get_viewport().get_final_transform() * ui_pos
	Input.warp_mouse(screen)
	var ev := InputEventMouseMotion.new()
	ev.position = screen
	ev.global_position = screen
	Input.parse_input_event(ev)


## The whole zone on one screen, lit enough to read the layout; the minimap fully revealed.
func overview() -> void:
	var vs: Vector2 = g.get_viewport_rect().size
	var map: Vector2 = g.layout.size_px()
	var k: float = minf(vs.x / map.x, vs.y / map.y)
	g.camera.limit_left = -100000
	g.camera.limit_top = -100000
	g.camera.limit_right = 100000
	g.camera.limit_bottom = 100000
	g.camera.target = null
	g.camera.zoom = Vector2(k, k)
	g.camera.global_position = map / 2.0
	g.camera.reset_smoothing()
	for n: Node in g.get_children():
		if n is CanvasModulate:
			(n as CanvasModulate).color = OVERVIEW_DARK
	g.ui.minimap.reveal_all()
	g.ui.hud.visible = false
