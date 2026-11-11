class_name Waylamp
extends Interactable
## The Lamplighters' old road lamps. Lit, a waylamp holds back the Dusk around it (enemies there are not
## Shrouded), refills tonics and is where you wake if you fall. Relighting one is an event: the lamp takes time
## to catch, and the dark sends waves at it; stay near and keep it alive.

signal lit_up(lamp: Waylamp)

const STAY_RANGE: float = 420.0
const LIGHT_ENERGY: float = 1.1
const REWARD_ITEMS: int = 2

var lit: bool = false
var relighting: bool = false
var progress: float = 0.0
var _waves_sent: int = 0
var _light: PointLight2D


func _ready() -> void:
	title = String(GameData.story["lamps"].get(prop.get("lamp", ""), "Waylamp"))
	super()
	add_to_group(LightField.GROUP)
	_light = PointLight2D.new()
	_light.texture = LightTex.pool()
	_light.color = LanternLight.COLOR
	_light.position = Vector2(0, -56)
	_light.energy = 0.0
	add_child(_light)
	if bool(prop.get("lit", false)):
		set_lit(true)


func light_pos() -> Vector2:
	return global_position


func light_radius() -> float:
	return float(GameData.light["waylamp_radius"]) if lit else 0.0


func set_lit(on: bool) -> void:
	lit = on
	PropSprite.set_frame(sprite, 1 if on else 0)
	_light.energy = LIGHT_ENERGY if on else 0.0
	_light.texture_scale = float(GameData.light["waylamp_radius"]) / LanternLight.TEX_RADIUS
	title = (title.trim_suffix(" (relight)") if on else title + " (relight)") if title != "" else title


func use(g: Game) -> void:
	if lit:
		g.player.refill_tonics()
		g.player.respawn_at = stand_point()
		g.hud.notice("Tonics refilled")
		g.ui.open(g.ui.travel)
		return
	if not relighting:
		relighting = true
		g.hud.caption(String(GameData.story["captions"]["relight_start"]))
		Audio.sfx("relight", -4.0)


func _process(delta: float) -> void:
	if not relighting or lit:
		return
	var g: Game = Game.current
	if g.player.global_position.distance_to(global_position) > STAY_RANGE:
		return
	var R: Dictionary = GameData.biome["relight"]
	if R.is_empty():
		return
	progress += delta / float(R["duration"])
	var due: int = int(progress * int(R["waves"])) + 1
	if _waves_sent < mini(due, int(R["waves"])):
		_waves_sent += 1
		g.spawner.wave(global_position, int(R["wave_size"]), R["kinds"], g.spawner.level_at(g.progress_at(global_position)))
	_light.energy = LIGHT_ENERGY * progress * 0.5
	_light.texture_scale = float(GameData.light["waylamp_radius"]) * progress / LanternLight.TEX_RADIUS
	if progress >= 1.0:
		_complete(g)


func _complete(g: Game) -> void:
	relighting = false
	set_lit(true)
	Audio.sfx("lamp_lit", -2.0)
	Fx.flash(g.fx_layer, global_position + Vector2(0, -56), 300.0, Pal.c("gold"), 2.0, 0.8)
	Fx.burst(g.fx_layer, global_position + Vector2(0, -56), 30, Vector2(60, 200), 0.8, [Pal.c("sun"), Pal.c("amber"), Pal.c("ember", 0.0)])
	g.hud.caption(String(GameData.story["captions"]["lamp_lit"]))
	g.player.respawn_at = stand_point()
	g.player.refill_tonics()
	g.spawner.drop_items(global_position, REWARD_ITEMS, "chest", g.spawner.level_at(g.progress_at(global_position)) + 1)
	lit_up.emit(self)
	Session.campaign.notify("lamp_lit", g.zone_id)
	g.mark_dirty()
