class_name Noon
extends Skill
## For one breath, daylight: the world lights up, every enemy you can see takes a great sunfire hit and reels,
## and your lantern blazes at full for a while. Tree: harder, longer blaze, burning, faster recovery, a healing
## bell, and a Second Sun left where you stood.

const SECOND_SUN_TIME: float = 6.0
const SECOND_SUN_RADIUS: float = 120.0
const SECOND_SUN_PCT: float = 30.0
const DAYLIGHT := Color(1.7, 1.6, 1.35)       ## a breath of day: well above any zone's ambient (HDR 2D)
const DAY_HOLD: float = 0.35
const DAY_FADE: float = 1.2
const SCREEN_FLASH: float = 0.6        ## Noon whites out the view for a moment


func cooldown() -> float:
	return super() / (1.0 + val("cdr_pct") / 100.0)


func use(_target: Vector2) -> void:
	var g: Game = Game.current
	g.shift_darkness(DAYLIGHT, DAY_HOLD, DAY_FADE)
	NoonFx.spawn(g.ui)
	Audio.sfx("lamp_lit", 0.0, 1.3)
	Audio.sfx("slam", -4.0, 1.4)
	CameraRig.shake(0.6)
	Fx.screen_flash(Color(1.0, 0.97, 0.85), SCREEN_FLASH, 0.4)
	HitStop.trigger(p.get_tree(), 0.08)
	var more: float = 1.0 + val("more_pct") / 100.0
	for e: Enemy in on_screen():
		Combat.hit_enemy(e, roll(), opts({"dir": e.global_position - p.global_position, "more": more,
			"stun": float(data["stun"]), "knockback": 30.0, "heavy": true}))
		if val("burn_pct") > 0.0 and is_instance_valid(e) and not e.dead:
			e.ignite(roll() * more * val("burn_pct") / 100.0)
	p.light.blaze(float(data["blaze"]) + val("blaze"))
	if rank("noon_bell") > 0:
		p.gain_life(p.stats.max_life() * val("heal_pct") / 100.0)
	if rank("second_sun") > 0:
		var b: Vector2 = base_range(SECOND_SUN_PCT)
		BurningGround.spawn(fx(), p.global_position, SECOND_SUN_RADIUS, SECOND_SUN_TIME, (b.x + b.y) * 0.5, self)
		Fx.flash(fx(), p.global_position, SECOND_SUN_RADIUS * 2.0, Pal.c("gold"), 1.2, SECOND_SUN_TIME)


## Every living enemy inside the camera's view.
func on_screen() -> Array[Enemy]:
	var view := Rect2(Game.current.camera.get_screen_center_position() - p.get_viewport_rect().size / 2.0, p.get_viewport_rect().size)
	var out: Array[Enemy] = []
	for n: Node in p.get_tree().get_nodes_in_group("enemies"):
		if view.has_point((n as Enemy).global_position):
			out.append(n)
	return out


func info() -> Array:
	var r: Vector2 = shown_range()
	return [["Every enemy on screen: %d-%d sunfire, stunned %.1f s" % [r.x, r.y, float(data["stun"])], UiDraw.TEXT],
		["Your Light blazes at full for %.0f s" % (float(data["blaze"]) + val("blaze")), UiDraw.TEXT]]
