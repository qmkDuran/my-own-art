extends Node
## --animreel: a ~30 s showcase of the Lamplighter's animations in the real game (record it with --write-movie):
## he runs two circles (all eight facings), streams Wickbolts in four directions, casts, throws the lantern and calls
## it back, dashes, takes two hits, falls and rises again. No enemies: only him and his light.

const OPEN_ROLE: String = "field"             ## an open clearing (Hollin's Ford), so the camera keeps him centred
const RING: float = 80.0
const RING_POINTS: int = 16
const STEP: float = 0.42
const BOLT_GAP: float = 0.3
const DIRS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
const AIM: float = 120.0

var g: Game
var h: ShotHelper


func _ready() -> void:
	_run.call_deferred()


func _wait(s: float) -> void:
	await get_tree().create_timer(s, false).timeout


func _run() -> void:
	while Game.current == null:
		await get_tree().process_frame
	await _wait(0.5)
	g = Game.current
	h = ShotHelper.new(g)
	h.level_up(12)
	h.clear_near(100000.0)
	g.camera.frames = []                                    # keep him centred: no arrival pan, no lean to landmarks
	g.camera.intro(g.player.global_position, 0.0)
	var open: Dictionary = g.layout.clearing_of_role(OPEN_ROLE)
	var at: Vector2 = g.layout.center_of(open["center"]) if not open.is_empty() else g.player.global_position
	h.place_player(g.layout.free_spot_near(at, 40.0))
	g.player.light.value = 70.0
	await _wait(1.0)
	await _circles()
	await _bolts()
	await _casts()
	await _dashes()
	await _hits()
	await _wait(1.0)
	get_tree().quit()


func _circles() -> void:
	var c: Vector2 = g.player.global_position + Vector2(0, -RING)
	for k: int in RING_POINTS * 2:
		var a: float = TAU * k / RING_POINTS + PI / 2.0
		g.player.walk_to(c + Vector2(cos(a), sin(a)) * RING)
		await _wait(STEP)
	g.player.stop()
	await _wait(0.6)


func _bolts() -> void:
	for d: Vector2 in DIRS:
		for beat: int in 3:
			h.cast("wickbolt", g.player.global_position + d * AIM)
			await _wait(BOLT_GAP)
		await _wait(0.5)


func _casts() -> void:
	h.cast("flare", g.player.global_position + Vector2(90, 60))
	await _wait(0.9)
	h.cast("flare", g.player.global_position + Vector2(-90, -60))
	await _wait(0.9)
	h.cast("lantern_toss", g.player.global_position + Vector2(-160, 40))
	await _wait(0.6)
	g.player.walk_to(g.player.global_position + Vector2(60, 40))
	await _wait(1.2)
	(g.player.skills.skill("lantern_toss") as LanternToss).recall()
	await _wait(1.2)


func _dashes() -> void:
	g.player.dash(g.player.global_position + Vector2(200, 0))
	await _wait(0.8)
	g.player.dash(g.player.global_position + Vector2(-150, 120))
	await _wait(0.9)


func _hits() -> void:
	for k: int in 2:
		g.player.take_hit(g.player.stats.max_life() * 0.08, g.player.global_position + Vector2(60, -20), 0.0)
		await _wait(0.8)
	g.player.respawn_at = g.player.global_position
	g.player.take_hit(g.player.life + 1.0, g.player.global_position + Vector2(60, -20), 0.0)
	await _wait(4.0)
