class_name BellwrightBrain
extends EnemyBrain
## The Bellwright (Act 2 boss). It plods after you and works the rope: TOLL (rings of sound roll outward from it;
## stand in the gaps or Wickstep through), DROP (bells fall on circles around you), CALL (Undertows climb out of the
## water), LULL (the Lull Bell: your lantern is smothered for a while). Below half life every toll is two rings.

const PATTERN: Array[String] = ["toll", "drop", "call", "toll", "lull", "drop"]
const WALK_TIME: float = 1.6
const PHASE2_AT: float = 0.5
const PHASE2_PACE: float = 0.75
const RING_GAP: float = 0.55
const DROP_SCATTER: float = 130.0
const CALL_RING: float = 90.0

var _i: int = 0
var _action: String = ""
var phase2: bool = false


func _think(_delta: float) -> Vector2:
	var d: Dictionary = e.data
	if not phase2 and e.life < e.max_life * PHASE2_AT:
		phase2 = true
		Game.current.hud.notice("The Bellwright pulls harder — two rings to every toll")
		CameraRig.shake(0.5)
	var pace: float = PHASE2_PACE if phase2 else 1.0
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
	if t <= 0.0:
		_begin(PATTERN[_i % PATTERN.size()], d, pace)
		_i += 1
		return Vector2.ZERO
	return chase(player().global_position, e.speed)


func _begin(action: String, d: Dictionary, pace: float) -> void:
	_action = action
	state = "windup"
	t = float(d["windup"]) * pace
	Audio.sfx("boss_wind", -6.0, 0.7 if action == "lull" else 1.0)
	if action == "lull":
		Game.current.hud.caption("It hauls the rope. You know this sound. Something in the lantern knows it too.")


func _fire(d: Dictionary) -> void:
	match _action:
		"toll":
			for k: int in (2 if phase2 else 1):
				Game.current.get_tree().create_timer(k * RING_GAP, false).timeout.connect(_ring.bind(d))
		"drop":
			_drop(d)
		"call":
			_call(int(d["call"]))
		"lull":
			Audio.sfx("lamp_lit", 0.0, 0.5)
			player().light.smother(float(d["lull_time"]))
			Fx.halo(Game.current.fx_layer, e.global_position, 300.0, Pal.c("gold", 0.5), 0.8)
			CameraRig.shake(0.4)


func _ring(d: Dictionary) -> void:
	if is_instance_valid(e) and not e.dead:
		Audio.sfx("lamp_lit", -4.0, 0.8)
		RingWave.spawn(Game.current.fx_layer, e.global_position, d, e)


func _drop(d: Dictionary) -> void:
	var fx: Node2D = Game.current.fx_layer
	var dmg: float = e.damage * float(d["drop_mult"])
	var r: float = float(d["drop_radius"])
	for k: int in int(d["drops"]) + (2 if phase2 else 0):
		var at: Vector2 = player().global_position + (Vector2.ZERO if k == 0 else Vector2(randf_range(-1, 1), randf_range(-1, 1)) * DROP_SCATTER)
		Telegraph.circle(fx, at, r, 1.0 + k * 0.1).fired.connect(func() -> void:
			Fx.burst(fx, at, 18, Vector2(60, 180), 0.5, [Pal.c("gold"), Pal.c("earth_lt"), Pal.c("earth", 0.0)], Vector2.UP, 180.0)
			Fx.flash(fx, at, r * 2.2, Pal.c("gold"), 1.1, 0.25)
			Audio.sfx("slam", -8.0, 1.3)
			CameraRig.shake(0.2)
			var p: Player = Game.current.player
			if p.global_position.distance_to(at) < r + p.radius:
				Combat.hit_player(null, dmg, "blunt", at))


func _call(n: int) -> void:
	var sp: Spawner = Game.current.spawner
	for k: int in n:
		var at: Vector2 = Game.current.layout.free_spot_near(e.global_position + Vector2.RIGHT.rotated(TAU * k / n) * CALL_RING, 14.0)
		sp.spawn("undertow", at, "normal", [], e.level).wake()
		Fx.burst(Game.current.fx_layer, at, 12, Vector2(30, 90), 0.5, [Pal.c("glint"), Pal.c("glass", 0.0)], Vector2.UP, 40.0)
