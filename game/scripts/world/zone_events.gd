class_name ZoneEvents
extends Node
## A zone's story moments, from its biome's `events`: the arrival caption, an ambush on a first visit, the boss
## (rises when you come near, its music, what its death frees), and the game-wide tips. Reports to the campaign.

const AMBUSH_DELAY: float = 2.5
const DARK_TIP_LIGHT: float = 40.0

var g: Game
var ev: Dictionary


func setup(game: Game) -> void:
	g = game
	ev = GameData.biome.get("events", {})
	var C: Dictionary = GameData.story["captions"]
	if ev.has("caption"):
		g.hud.caption(String(ev["caption"]))
	if ev.has("ambush") and not Session.campaign.flags.has("ambush_" + g.zone_id):
		Session.campaign.set_flag("ambush_" + g.zone_id)
		get_tree().create_timer(AMBUSH_DELAY, false).timeout.connect(func() -> void:
			if g.spawner.opening_ambush(ev["ambush"]):
				g.hud.caption(String(C["ambush"])))
	if g.flags.has("boss_down"):
		_after_boss(true)


func _process(_delta: float) -> void:
	var c: Campaign = Session.campaign
	if not c.flags.has("tip_dark") and g.player.light.value < DARK_TIP_LIGHT:
		c.set_flag("tip_dark")
		g.hud.caption(String(GameData.story["captions"]["first_dark"]))
	if not c.flags.has("tip_level") and g.player.prog.level >= 2:
		c.set_flag("tip_level")
		g.hud.caption(String(GameData.story["captions"]["first_level"]))
	if ev.has("boss") and not g.flags.has("boss") and not g.flags.has("boss_down") \
			and g.player.global_position.distance_to(g.layout.circle_center()) < float(ev["boss"]["trigger"]):
		start_boss()


func start_boss() -> void:
	if g.flags.has("boss") or g.flags.has("boss_down") or not ev.has("boss"):
		return
	var B: Dictionary = ev["boss"]
	g.flags["boss"] = true
	var b: Enemy = g.spawner.spawn_boss()
	b.wake()
	g.hud.track_boss(b)
	g.camera.focus = b
	g.hud.caption(String(B["caption"]))
	Audio.play_music(String(B.get("music", "boss")), 1.0)
	Audio.sfx("boss_wind", -2.0, 0.6)
	Session.campaign.notify("boss_seen", String(B["kind"]))
	g.spawner.boss_died.connect(func(_e: Enemy) -> void: _boss_down(), CONNECT_ONE_SHOT)


func _boss_down() -> void:
	g.flags["boss_down"] = true
	Audio.play_music(String(GameData.zone(g.zone_id)["music"]), 3.0)
	Session.campaign.notify("boss_down", String(ev["boss"]["kind"]))
	_after_boss(false)
	g.mark_dirty()


## What the boss was holding: the glass shell breaks (or is already broken on a later visit) and someone steps out.
func _after_boss(quiet: bool) -> void:
	var R: Dictionary = ev["boss"].get("frees", {})
	if R.is_empty() or g.cocoon == null:
		return
	if quiet:
		g.cocoon.open_quietly()
	else:
		g.cocoon.shatter(g)
	if Session.campaign.past(String(R["quest"][0]), int(R["quest"][1])):
		return
	var npc := Npc.new()
	npc.setup({"kind": "npc", "npc": String(R["npc"]), "pos": g.cocoon.global_position + Vector2(0, 24), "foot": Rect2()})
	g.world.add_child(npc)
