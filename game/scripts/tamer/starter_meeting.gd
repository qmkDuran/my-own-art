class_name StarterMeeting
extends Node
## The opening: three young creatures wait in the meadow (a brave honey badger, a playful cuttlefish, a shy
## pangolin). Walk up to each and it reacts in its own way (puffs up, flickers through its colours, curls into a
## ball) with a line about it; click the one you want. It becomes your partner; the other two hop off into the
## grass (they are not gone for good, the vision says: they turn up again later).

signal picked(rec: CreatureRecord)

const SIDE: String = "meet"
const PUFF := Vector2(1.35, 1.25)
const CURL := Vector2(1.1, 0.55)
const REACT_TIME: float = 0.9
const FLICKER_STEPS: int = 8
const LEAVE_TIME: float = 0.7
const LEAVE_HOP: float = 60.0

var g: TamerGame
var waiting: Array[Creature] = []
var _reacted: Dictionary = {}
var done: bool = false


func setup(game: TamerGame) -> void:
	g = game
	var spots: Array = TamerData.rule("meet.spots")
	var ids: Array = TamerData.starters()
	for i: int in ids.size():
		var rec := CreatureRecord.make(String(ids[i]), int(TamerData.rule("starter_level")), false)
		var c := Creature.new().setup(rec, SIDE)
		c.position = g.layout.free_spot_near(g.layout.start + Vector2(float(spots[i][0]), float(spots[i][1])), rec.radius())
		c.brain = MeetBrain.new(c)
		g.world.add_child(c)
		CreatureTag.attach(c)
		waiting.append(c)
	g.hud.caption(String(TamerData.rule("meet.caption")))


func _process(_delta: float) -> void:
	if done:
		return
	for c: Creature in waiting:
		var near: bool = c.global_position.distance_to(g.trainer.global_position) < float(TamerData.rule("meet.react_range"))
		if near and not _reacted.has(c):
			_reacted[c] = true
			react(c)


## Each starter shows who it is when you come close.
func react(c: Creature) -> void:
	var meet: Dictionary = c.rec.data()["meet"]
	g.hud.caption(String(meet["line"]))
	var s: Sprite2D = c.view.sprite
	var tw := c.create_tween()
	match String(meet["react"]):
		"puff":
			tw.tween_property(s, "scale", PUFF, REACT_TIME * 0.3).set_trans(Tween.TRANS_BACK)
			tw.tween_property(s, "scale", Vector2.ONE, REACT_TIME * 0.7)
			TamerFx.blast(c.global_position, 34.0, c.element_id())
			Audio.sfx("hiss", -8.0, 1.4)
		"flicker":
			for k: int in FLICKER_STEPS:
				var el: String = ["glass", "echo", "tide", "ember"][k % 4]
				tw.tween_property(s, "modulate", TamerData.color(el, "light") * 1.4, REACT_TIME / FLICKER_STEPS)
			tw.tween_property(s, "modulate", Color.WHITE, 0.1)
			Audio.sfx("shard", -8.0, 1.5)
		"curl":
			tw.tween_property(s, "scale", CURL, REACT_TIME * 0.25)
			tw.tween_interval(REACT_TIME * 0.5)
			tw.tween_property(s, "scale", Vector2.ONE, REACT_TIME * 0.25).set_trans(Tween.TRANS_BACK)
			Audio.sfx("step", -6.0, 0.8)


## Clicking a starter picks it. Returns whether the click was taken.
func pick(c: Creature) -> bool:
	if done or not waiting.has(c):
		return false
	done = true
	for o: Creature in waiting:
		if o == c:
			continue
		var tw := o.create_tween()
		var away: Vector2 = (o.global_position - g.layout.start).normalized() * LEAVE_HOP
		tw.tween_property(o, "global_position", o.global_position + away, LEAVE_TIME)
		o.view.fade_out(LEAVE_TIME)
		tw.tween_callback(o.queue_free)
	var rec: CreatureRecord = c.rec
	c.queue_free()
	g.team.add(rec)
	g.field.summon(0, false)
	TamerFx.celebrate(g.field.partner, rec.element())
	g.hud.caption("%s chose you back. Let's go!" % rec.data()["name"])
	picked.emit(rec)
	return true
