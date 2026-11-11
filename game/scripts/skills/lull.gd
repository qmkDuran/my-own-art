class_name Lull
extends Skill
## Strike the lantern like a bell: a ring of sound stuns everything near you. Deep Toll, Wide Toll, Resonance
## (Oil back), Echo (rings again at half strength), Hush (the stunned take more damage).

const ECHO_DELAY: float = 1.0
const ECHO_SCALE: float = 0.5
const HUSH_PCT: float = 25.0


func radius() -> float:
	return float(data["radius"]) * (1.0 + val("area_pct") / 100.0) * p.stats.area_mult()


func use(_target: Vector2) -> void:
	_ring(1.0)
	var clapper: bool = p.stats.has_special("clapper")
	if rank("echo") > 0 or clapper:
		p.get_tree().create_timer(ECHO_DELAY, false).timeout.connect(_ring.bind(1.0 if clapper else ECHO_SCALE))


func _ring(strength: float) -> void:
	var at: Vector2 = p.global_position
	BurstFx.spawn(fx(), at + Vector2(0, -10), radius())
	Fx.flash(fx(), at, radius() * 1.4, Pal.c("glint"), 1.0 * strength, 0.3)
	Audio.sfx("lamp_lit", -6.0, 1.8 / (1.0 + strength))
	CameraRig.shake(0.15 * strength)
	var n: int = hit_area(at, radius(), 100.0 * strength, {"stun": (float(data["stun"]) + val("stun")) * strength, "knockback": 20.0})
	p.oil = minf(p.stats.max_oil(), p.oil + val("oil") * n)
	if rank("hush") > 0:
		for e: Enemy in enemies_in_arc(at, Vector2.RIGHT, radius(), 360.0):
			e.expose(HUSH_PCT, float(data["stun"]) + val("stun"))


func info() -> Array:
	var r: Vector2 = shown_range()
	return [["Radius %d px: %d-%d, stuns %.1f s" % [roundi(radius()), r.x, r.y, float(data["stun"]) + val("stun")], UiDraw.TEXT]]
