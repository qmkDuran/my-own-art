class_name MatronBrain
extends EnemyBrain
## The Moth Matron (Act 1 boss). She hovers at a distance and works through a readable cycle: GUST (a cone fills
## toward you, then her wings shove and hurt), DUST (circles fill around you and become clouds that drink your
## Light), BROOD (mirror moths hatch around her), SMOTHER (she folds her wings over your lantern: for a few
## seconds your light is an ember). Below half life she is faster and her brood larger.

const PATTERN: Array[String] = ["gust", "dust", "brood", "gust", "smother", "dust"]
const HOLD: float = 170.0
const DRIFT: float = 0.6
const PHASE2_AT: float = 0.5
const PHASE2_PACE: float = 0.7
const PHASE2_BROOD: int = 2
const GUST_PUSH: float = 520.0
const DUST_SCATTER: float = 120.0
const DUST_DELAY: float = 1.0
const BROOD_RING: float = 70.0
const RECOVER: float = 1.4

var _i: int = 0
var _action: String = ""
var _aim: Vector2
var phase2: bool = false


func _think(_delta: float) -> Vector2:
	var d: Dictionary = e.data
	if not phase2 and e.life < e.max_life * PHASE2_AT:
		phase2 = true
		Game.current.hud.notice("The Matron tears her wings free — she is faster now")
		CameraRig.shake(0.5)
	var pace: float = PHASE2_PACE if phase2 else 1.0
	match state:
		"windup":
			if t <= 0.0:
				_fire(d)
				state = "recover"
				t = RECOVER * pace
			return Vector2.ZERO
		"recover":
			if t <= 0.0:
				state = "chase"
				t = float(d["cooldown"]) * pace
			return _hover_velocity()
	if t <= 0.0:
		_begin(PATTERN[_i % PATTERN.size()], d, pace)
		_i += 1
		return Vector2.ZERO
	return _hover_velocity()


## Keep a hovering distance from the Lamplighter, drifting around him.
func _hover_velocity() -> Vector2:
	var v: Vector2 = to_player()
	var want: Vector2 = v.normalized() * (v.length() - HOLD)
	return (want.limit_length(e.speed) + v.normalized().orthogonal() * e.speed * DRIFT)


func _begin(action: String, d: Dictionary, pace: float) -> void:
	_action = action
	state = "windup"
	t = float(d["windup"]) * pace
	var fx: Node = Game.current.fx_layer
	match action:
		"gust":
			_aim = to_player().normalized()
			Telegraph.cone(fx, e.global_position, _aim, float(d["gust_range"]), float(d["gust_arc"]), t)
			Audio.sfx("boss_wind", -6.0, 1.3)
		"dust":
			t = DUST_DELAY * pace
			_dust(d, t)
		"smother":
			Game.current.hud.caption("She folds her wings over the light.")
			Audio.sfx("boss_wind", -4.0, 0.7)
		"brood":
			Audio.sfx("moths", -4.0, 0.7)


func _fire(d: Dictionary) -> void:
	var fx: Node = Game.current.fx_layer
	match _action:
		"gust":
			Fx.burst(fx, e.global_position + _aim * 60.0, 30, Vector2(120, 300), 0.5, [Pal.c("pale"), Pal.c("mist"), Pal.c("dusk3", 0.0)],
				_aim, float(d["gust_arc"]) * 0.5, Vector2(1, 2))
			CameraRig.shake(0.35)
			var v: Vector2 = to_player()
			if v.length() < float(d["gust_range"]) and absf(_aim.angle_to(v)) < deg_to_rad(float(d["gust_arc"])) * 0.5:
				Combat.hit_player(e, e.damage * 1.3, "dusk", e.global_position)
				player().push(_aim * GUST_PUSH)
		"smother":
			player().light.smother(float(d["smother_time"]))
			Fx.halo(fx, player().global_position, 140.0, Pal.c("violet", 0.6), 0.6)
		"brood":
			_brood(int(d["brood"]) + (PHASE2_BROOD if phase2 else 0))


func _dust(d: Dictionary, delay: float) -> void:
	var fx: Node2D = Game.current.fx_layer
	for k: int in int(d["dust_count"]):
		var at: Vector2 = player().global_position
		if k > 0:
			at += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * DUST_SCATTER
		var r: float = float(d["dust_radius"])
		var life: float = float(d["dust_time"])
		Telegraph.circle(fx, at, r, delay + k * 0.1).fired.connect(func() -> void:
			var h: HungerZone = HungerZone.make(fx, at, r)
			h.life = life)


func _brood(n: int) -> void:
	var sp: Spawner = Game.current.spawner
	for k: int in n:
		var at: Vector2 = Game.current.layout.free_spot_near(e.global_position + Vector2.RIGHT.rotated(TAU * k / n) * BROOD_RING, 13.0)
		var m: Enemy = sp.spawn("moth", at, "normal", [], e.level)
		m.wake()
		Fx.burst(Game.current.fx_layer, at, 10, Vector2(30, 90), 0.5, [Pal.c("amber"), Pal.c("violet", 0.0)])
