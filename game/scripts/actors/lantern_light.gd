class_name LanternLight
extends Node2D
## The lantern's Light (data/light.json): a value from min to max that sets the radius. Hits dim it, kills feed
## it, and it drifts back into a calm band so a bad moment never stays punishing. Blazing (high) adds damage;
## Guttering (low) is a warning. Drawn as a banded warm light with a faint ring at the radius that matters.

signal state_changed(state: String)

const COLOR := Color(1.0, 0.9, 0.74)     ## warm but near white, so what it lights keeps its own colours
const ENERGY: float = 0.75          ## the pool is ambient + this: bright and warm, never blown out on pale stone
const HALO_ENERGY: float = 0.28
const SHADOW_ALPHA: float = 0.75
const HALO_SCALE: float = 1.7
const TEX_RADIUS: float = 128.0
const FLICKER: float = 0.05
const RADIUS_LERP: float = 6.0
const RING_DASHES: int = 48
const RING_Z: int = -15
const HIT_FLASH_TIME: float = 0.35
const LIGHTHOUSE_CAP: float = 60.0

var value: float
var stats: Stats
var thrown: bool = false
var _smother_t: float = 0.0
var _blaze_t: float = 0.0
var shown_radius: float = 0.0
var _light: PointLight2D
var _halo: PointLight2D
var _floor: PointLight2D
var _state: String = "calm"
var _hit_flash: float = 0.0
var _t: float = 0.0
var _pane: float = 1.0


func _ready() -> void:
	var L: Dictionary = GameData.light
	value = float(L["start"])
	_light = _make_light(LightTex.banded(), ENERGY, Fx.STANDING_MASK, false)    # people, props, trees: no shadows on them
	_floor = _make_light(LightTex.banded(), ENERGY, Fx.FLOOR_MASK, true)        # the ground: shadows fall here, away from the light
	_halo = _make_light(LightTex.soft(256), HALO_ENERGY, Fx.FLOOR_MASK | Fx.STANDING_MASK, false)
	z_index = RING_Z
	z_as_relative = false
	material = Fx.unshaded()
	add_to_group(LightField.GROUP)
	shown_radius = target_radius()


## A lantern light touching only `mask`; `shadows`: trunks, pillars and walls throw moving shadows (on the floor only,
## so a house is never darkened by its own shadow and nobody standing in front of it is covered).
func _make_light(tex: Texture2D, energy: float, mask: int, shadows: bool) -> PointLight2D:
	var l := PointLight2D.new()
	l.range_item_cull_mask = mask
	l.shadow_enabled = shadows and int(Atmosphere.quality()["shadows"]) > 0
	l.shadow_filter = Atmosphere.quality()["filter"]
	l.shadow_color = Color(0, 0, 0, SHADOW_ALPHA)
	l.texture = tex
	l.color = COLOR
	l.energy = energy
	add_child(l)
	return l


func target_radius() -> float:
	var L: Dictionary = GameData.light
	var v: float = float(L["thrown_lantern_self_light"]) if thrown or _smother_t > 0.0 else value
	var mult: float = stats.light_radius_mult() if stats != null else 1.0
	return (float(L["radius_base"]) + float(L["radius_per_light"]) * v) * mult


func light_pos() -> Vector2:
	return global_position


## The pool follows the lantern as it swings (offset from the Lamplighter's feet); `pane` dims it as the lantern
## gutters (his death) and brings it back as it relights. The Light ring and the gameplay radius stay put.
func sway(at: Vector2, pane: float) -> void:
	_light.position = at
	_floor.position = at
	_halo.position = at
	_pane = pane


func light_radius() -> float:
	return shown_radius


func state() -> String:
	var L: Dictionary = GameData.light
	if value >= float(L["blazing_at"]) and not thrown:
		return "blazing"
	if value < float(L["guttering_below"]):
		return "guttering"
	return "calm"


## Something folds its wings over the lantern: the light shrinks to an ember for a while.
func smother(seconds: float) -> void:
	_smother_t = maxf(_smother_t, seconds)


## Noon: the lantern blazes at full for a while (no hit dims it, it does not settle).
func blaze(seconds: float) -> void:
	_blaze_t = maxf(_blaze_t, seconds)
	value = float(GameData.light["max"])


func smothered() -> bool:
	return _smother_t > 0.0


func add(amount: float) -> void:
	var L: Dictionary = GameData.light
	if _blaze_t > 0.0:
		return
	var top: float = LIGHTHOUSE_CAP if stats != null and stats.has_special("lighthouse") else float(L["max"])
	value = clampf(value + amount, float(L["min"]), top)


## A hit for `fraction` of max life dims the lantern (less with Steady Flame and the like).
func on_hit(fraction: float, extra: float) -> void:
	_hit_flash = HIT_FLASH_TIME
	if stats.has_special("lighthouse"):
		return
	var L: Dictionary = GameData.light
	var loss: float = (float(L["hit_loss_flat"]) + float(L["hit_loss_per_life_fraction"]) * fraction) \
		* (1.0 - minf(0.9, stats.v("light_loss_reduction") / 100.0)) + extra
	add(-loss)


func on_kill(rank: String) -> void:
	var L: Dictionary = GameData.light
	var gain: float = float(L.get("kill_gain_" + rank, L["kill_gain"])) if rank != "normal" else float(L["kill_gain"])
	add(gain + stats.v("light_on_kill"))


func _process(delta: float) -> void:
	_t += delta
	_smother_t = maxf(0.0, _smother_t - delta)
	_blaze_t = maxf(0.0, _blaze_t - delta)
	_drift(delta)
	shown_radius = lerpf(shown_radius, target_radius(), minf(1.0, delta * RADIUS_LERP))
	var flick: float = 1.0 + sin(_t * 13.0) * FLICKER * 0.5 + sin(_t * 7.3) * FLICKER * 0.5
	_light.texture_scale = shown_radius / TEX_RADIUS
	_light.energy = ENERGY * flick * _pane
	_floor.texture_scale = _light.texture_scale
	_floor.energy = _light.energy
	_halo.texture_scale = shown_radius * HALO_SCALE / TEX_RADIUS
	_hit_flash = maxf(0.0, _hit_flash - delta)
	Audio.set_muffled(thrown or _smother_t > 0.0)
	var s: String = state()
	if s != _state:
		_state = s
		state_changed.emit(s)
	queue_redraw()


func _drift(delta: float) -> void:
	if _blaze_t > 0.0:
		return
	var L: Dictionary = GameData.light
	if value < float(L["calm_low"]):
		add(float(L["drift_up_per_s"]) * delta)
	elif value > float(L["calm_high"]):
		add(-float(L["drift_down_per_s"]) * delta)


func _draw() -> void:
	var alpha: float = float(GameData.light["ring_alpha"])
	var col: Color = Pal.c("rose", 0.6) if _hit_flash > 0.0 else Pal.c("gold" if _state == "blazing" else "amber", alpha)
	var step: float = TAU / RING_DASHES
	for i: int in RING_DASHES:
		var a: float = i * step + _t * 0.15
		draw_arc(Vector2.ZERO, shown_radius, a, a + step * 0.5, 3, col, 1.0)
