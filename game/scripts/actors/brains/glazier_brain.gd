class_name GlazierBrain
extends EnemyBrain
## The Glazier (mini-boss). A readable cycle: walk in, SLAM (a circle fills around it), VOLLEY (a ring of shards
## plus three aimed), RAIN (circles fill around you, then glass falls). Below half life it moves faster and its
## pauses shorten ("it is still trying to put the pieces back").

const PATTERN: Array[String] = ["slam", "volley", "rain", "slam", "rain", "volley"]
const WALK_TIME: float = 1.3
const PHASE2_AT: float = 0.5
const PHASE2_SPEED: float = 0.65
const AIMED_SHOTS: int = 3
const AIMED_SPREAD: float = 0.18
const RAIN_SCATTER: float = 140.0

var _i: int = 0
var _action: String = ""
var phase2: bool = false


func _think(_delta: float) -> Vector2:
	var d: Dictionary = e.data
	if not phase2 and e.life < e.max_life * PHASE2_AT:
		phase2 = true
		Game.current.hud.notice("The Glazier cracks — it moves faster")
		CameraRig.shake(0.5)
	var pace: float = PHASE2_SPEED if phase2 else 1.0
	match state:
		"windup":
			if t <= 0.0:
				_fire(d)
				state = "recover"
				t = float(d["cooldown"]) * pace
			return Vector2.ZERO
		"recover":
			if t <= 0.0:
				state = "chase"
				t = WALK_TIME * pace
			return Vector2.ZERO
	var near: bool = to_player().length() < float(d["range"]) + 40.0
	if t <= 0.0 or (near and PATTERN[_i % PATTERN.size()] == "slam"):
		_begin(PATTERN[_i % PATTERN.size()], d, pace)
		_i += 1
		return Vector2.ZERO
	return chase(player().global_position, e.speed * (1.3 if phase2 else 1.0))


func _begin(action: String, d: Dictionary, pace: float) -> void:
	_action = action
	state = "windup"
	t = float(d["windup"]) * pace
	var fx: Node = Game.current.fx_layer
	match action:
		"slam":
			Telegraph.circle(fx, e.global_position, float(d["slam_radius"]), t)
			Audio.sfx("boss_wind", -6.0, 0.8)
		"volley":
			Audio.sfx("boss_wind", -8.0, 1.1)
		"rain":
			t = float(d["rain_delay"]) * pace
			_rain(d, t)


func _fire(d: Dictionary) -> void:
	match _action:
		"slam":
			Fx.burst(Game.current.fx_layer, e.global_position, 30, Vector2(80, 220), 0.6,
				[Pal.c("glint"), Pal.c("glass_lt"), Pal.c("glass", 0.0)], Vector2.UP, 180.0, Vector2(1, 2))
			Fx.flash(Game.current.fx_layer, e.global_position, float(d["slam_radius"]) * 1.5, Pal.c("glass_lt"), 1.3, 0.35)
			CameraRig.shake(0.55)
			Audio.sfx("slam", -2.0)
			if to_player().length() < float(d["slam_radius"]) + player().radius:
				Combat.hit_player(e, e.damage * 1.6, "blunt", e.global_position)
		"volley":
			var n: int = int(d["volley"])
			for k: int in n:
				shoot(Vector2.RIGHT.rotated(TAU * k / n + _i * 0.3), float(d["shot_speed"]))
			for k: int in AIMED_SHOTS:
				shoot(to_player().rotated((k - 1) * AIMED_SPREAD), float(d["shot_speed"]) * 1.3)
			Audio.sfx("shard", -4.0, 0.8)


## Glass falls from the dark onto circles around the Lamplighter (one right where they stand).
func _rain(d: Dictionary, delay: float) -> void:
	var fx: Node = Game.current.fx_layer
	var r: float = float(d["rain_radius"])
	var src_id: int = e.get_instance_id()
	var dmg: float = e.damage
	for k: int in int(d["rain_count"]):
		var at: Vector2 = player().global_position
		if k > 0:
			at += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * RAIN_SCATTER
		var tg: Telegraph = Telegraph.circle(fx, at, r, delay + k * 0.08)
		tg.fired.connect(func() -> void:
			Fx.burst(fx, at, 14, Vector2(60, 160), 0.45, [Pal.c("glint"), Pal.c("glass_lt"), Pal.c("glass", 0.0)], Vector2.UP, 180.0)
			Fx.flash(fx, at, r * 2.0, Pal.c("glass_lt"), 1.0, 0.2)
			Audio.sfx("die_glass", -10.0, randf_range(1.1, 1.4))
			var p: Player = Game.current.player
			if p.global_position.distance_to(at) < r + p.radius:
				Combat.hit_player(instance_from_id(src_id) as Enemy, dmg, "blunt", at))
