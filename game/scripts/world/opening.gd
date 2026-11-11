class_name Opening
extends Node
## The first hour's hand-holding, while "First Light" runs, all inside Tallow. On the fenced practice ground in the
## north of town: a lit marker to walk to, three straw targets for Wickbolt, a far marker to Wickstep toward, a
## cluster to Flare (each step completes when done). Then back to Captain Marr at the gate: the Great Lantern goes
## dark for seven heartbeats, something comes over the wall, and a small wave breaks through the gate; Marr fights
## beside you. Game.event_target is where the tracker points.

const QUEST: String = "first_light"
const MARKER_NEAR: float = 40.0
const ENTRY_AT := Vector2(0, 110)          ## just inside the gap in the ground's south fence
const GROUND_HALF := Vector2(240, 120)     ## half the fenced ground: inside it, you have arrived
const BACK_NEAR: float = 140.0             ## this close to Captain Marr counts as reporting back
const MOVE_AT := Vector2(140, 40)
const BOLT_AT := Vector2(-140, -30)
const DASH_AT := Vector2(140, -60)
const FLARE_AT := Vector2(0, -20)
const MARKS: Array[Vector2] = [ENTRY_AT, MOVE_AT, BOLT_AT, DASH_AT, FLARE_AT]   ## every drill spot (the layout check keeps them clear)
const DARK_BEATS: int = 7
const BEAT: float = 0.8
const DARK := Color(0.08, 0.07, 0.1)
const WAVE: Array[String] = ["gloam", "gloam", "gloam", "gloam"]
const WAVE_FROM := Vector2(0, 150)

var g: Game
var _step: int = -1
var _marker: Node2D
var _targets: Array[Enemy] = []
var _wave: Array[Enemy] = []
var _ally: Ally


func setup(game: Game) -> void:
	g = game


func _process(_delta: float) -> void:
	var c: Campaign = Session.campaign
	var step: int = c.step_index(QUEST)
	if step != _step:
		_step = step
		_enter(step)
	if g.zone_id != "tallow":
		return
	_yard_tick(step)
	if step == 8 and not _wave.is_empty() and _wave.all(func(e: Variant) -> bool: return not is_instance_valid(e) or (e as Enemy).dead):
		_wave.clear()
		if _ally != null:
			_ally.queue_free()
		c.notify("gate", "held")
		g.hud.caption("The gate holds. But the wall-walk is empty. Nim Saltry is gone. Something took her into the Glasswood.")


func _enter(step: int) -> void:
	if g.zone_id != "tallow":
		return
	match step:
		2: g.event_target = _at(ENTRY_AT)
		3: _mark(MOVE_AT)
		4: _spawn_targets()
		5: _mark(DASH_AT)
		6: _spawn_cluster()
		7: _clear_marker()
		8: _lantern_goes_dark()


func _yard_tick(step: int) -> void:
	var c: Campaign = Session.campaign
	var me: Vector2 = g.player.global_position
	var rel: Vector2 = (me - _at(Vector2.ZERO)).abs()
	if step == 2 and rel.x < GROUND_HALF.x and rel.y < GROUND_HALF.y:
		c.notify("yard", "enter")
	elif step == 7 and me.distance_to(Objectives.place(g, "npc:ysolde")) < BACK_NEAR:
		c.notify("yard", "back")
	elif step == 3 and me.distance_to(_at(MOVE_AT)) < MARKER_NEAR:
		c.notify("yard", "move")
	elif step == 5 and g.player.dashing() and me.distance_to(_at(DASH_AT)) < MARKER_NEAR * 3.0:
		c.notify("yard", "dash")


func _at(offset: Vector2) -> Vector2:
	return g.layout.center_of(g.layout.clearing_of_role("yard")["center"]) + offset


func _clear_marker() -> void:
	if _marker != null:
		_marker.queue_free()
		_marker = null


func _mark(offset: Vector2) -> void:
	_clear_marker()
	_marker = Node2D.new()
	_marker.position = _at(offset)
	_marker.set_script(preload("res://scripts/world/yard_marker.gd"))
	g.world.add_child(_marker)
	g.event_target = _marker.position


func _spawn_targets() -> void:
	_clear_marker()
	_targets = ShotHelper.new(g).pack_near(["dummy", "dummy", "dummy"], _at(BOLT_AT) - g.player.global_position)
	g.event_target = _at(BOLT_AT)
	for t: Enemy in _targets:
		t.died.connect(func(_e: Enemy) -> void: Session.campaign.notify("yard", "bolt"))


func _spawn_cluster() -> void:
	_clear_marker()
	var cluster: Array[Enemy] = ShotHelper.new(g).pack_near(["dummy", "dummy", "dummy"], _at(FLARE_AT) - g.player.global_position)
	g.event_target = _at(FLARE_AT)
	g.player.skills.used.connect(func(id: String) -> void:
		if id == "flare" and Session.campaign.step_index(QUEST) == 6:
			Session.campaign.notify("yard", "flare"))
	for t: Enemy in cluster:
		t.max_life *= 4.0
		t.life = t.max_life


## Seven heartbeats of dark, then the gate is breached.
func _lantern_goes_dark() -> void:
	g.hud.caption("The Great Lantern... is going out.")
	g.shift_darkness(DARK, DARK_BEATS * BEAT, 1.2)
	for k: int in DARK_BEATS:
		get_tree().create_timer(BEAT * (k + 1), false).timeout.connect(func() -> void:
			Audio.sfx("hit", -14.0, 0.5)
			CameraRig.shake(0.08))
	get_tree().create_timer(BEAT * DARK_BEATS + 0.5, false).timeout.connect(_breach)


func _breach() -> void:
	g.hud.caption("The Lantern burns again. But something came over the wall in the dark. They're at the gate!")
	var gate: Vector2 = g.layout.start + WAVE_FROM
	g.event_target = gate
	_wave = ShotHelper.new(g).pack_near(WAVE, gate - g.player.global_position)
	for e: Enemy in _wave:
		e.max_life *= 0.6
		e.life = e.max_life
	_ally = Ally.new()
	_ally.position = g.layout.free_spot_near(g.player.global_position + Vector2(40, 20), 12.0)
	g.world.add_child(_ally)
