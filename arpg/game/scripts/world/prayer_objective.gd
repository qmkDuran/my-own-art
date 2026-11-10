class_name PrayerObjective
extends Node
## Three people praying in the dark street (Rev 8:3-4: prayers rise like incense). Reach each one: the enemy sends a
## wave against that light; when the wave is put down, the prayer is answered (a star point is given).
## When all three are answered, a stronger pack comes with its hero; defeating it leaves better gifts.

signal progressed(answered: int, total: int)
signal caption(key: String)

const STATE_WAITING: int = 0
const STATE_DEFENDING: int = 1
const STATE_ANSWERED: int = 2

var world: Node2D
var michael: Michael
var spawner: Spawner
var points: Array[Dictionary] = []      # {at, state, wave: Array[Demon], light}
var final_wave: Array[Demon] = []
var finished: bool = false


func setup(into_world: Node2D, m: Michael, s: Spawner) -> void:
	world = into_world
	michael = m
	spawner = s
	for p: Dictionary in GameData.zone["prayers"]:
		var at: Vector2 = SceneData.vec(p["at"])
		var person := SpriteFactory.grounded(world, p["person"], at, 2)
		var light := PointLight2D.new()
		light.texture = LightTex.radial(256)
		light.color = Color(1.0, 0.86, 0.5)
		light.energy = 0.8
		light.position = at + Vector2(0, -20)
		world.add_child(light)
		Fx.incense(world, at + Vector2(0, -40))
		SkillFx.circle(world, at, float(GameData.zone["prayer_radius"]), Color(1.0, 0.85, 0.4))
		points.append({"at": at, "state": STATE_WAITING, "wave": [], "light": light, "person": person, "data": p})


func answered() -> int:
	return points.filter(func(p: Dictionary) -> bool: return p["state"] == STATE_ANSWERED).size()


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for p: Dictionary in points:
		var light: PointLight2D = p["light"]
		light.energy = (0.8 if p["state"] != STATE_ANSWERED else 1.3) + 0.15 * sin(t * 2.0 + p["at"].x)
		(p["person"] as Sprite2D).frame = int(t * 0.8 + p["at"].x) % 2
		match int(p["state"]):
			STATE_WAITING:
				if michael.global_position.distance_to(p["at"]) < float(GameData.zone["prayer_radius"]):
					_defend(p)
			STATE_DEFENDING:
				if _cleared(p["wave"]):
					_answer(p)
	if not final_wave.is_empty() and not finished and _cleared(final_wave):
		finished = true
		_reward()


func _defend(p: Dictionary) -> void:
	p["state"] = STATE_DEFENDING
	p["wave"] = spawner.spawn_wave(p["data"]["wave"], p["at"], 190.0)
	caption.emit("{incense}")
	Audio.sfx("bolt", -6.0, 0.6)


func _answer(p: Dictionary) -> void:
	p["state"] = STATE_ANSWERED
	michael.prog.grant_star()
	Audio.sfx("prayer", -4.0)
	SkillFx.ring(world, p["at"], 120.0, Color(1.0, 0.9, 0.5), 0.8)
	progressed.emit(answered(), points.size())
	caption.emit("{encamps}")
	if answered() == points.size():
		var f: Dictionary = GameData.zone["final_pack"]
		final_wave = spawner.spawn_wave(f["kinds"], SceneData.vec(f["at"]), 70.0)
		final_wave.append(spawner.spawn_hero(SceneData.vec(f["at"])))
		caption.emit("{war_heaven}")


func _reward() -> void:
	var at: Vector2 = SceneData.vec(GameData.zone["final_pack"]["at"])
	for r: String in ["unique", "rare", "rare", "magic"]:
		GroundItem.spawn(world, at + Vector2(randf_range(-40, 40), randf_range(-20, 20)), LootGen.make(spawner.area_level() + 2, 3.0, r))
	Audio.sfx("rare_drop", -3.0)
	caption.emit("{not_strong}")


static func _cleared(wave: Array) -> bool:
	for d: Variant in wave:
		if is_instance_valid(d) and not (d as Demon).dead:
			return false
	return true
