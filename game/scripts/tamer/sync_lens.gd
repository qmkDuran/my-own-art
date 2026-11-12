class_name SyncLens
extends Node2D
## Catching in an arena is the trainer's job, with a handheld scanner. Weaken the wild creature until gold stars
## show (dazed), then press F: the trainer raises the lens from the arena edge, a beam locks on, and a scan of 2.5 s
## runs (faster with the upgraded lens). Meanwhile the creature STRUGGLES (FoeBrain: telegraphed lunges at your
## creature); if your creature is hit, or you hit the creature, the scan breaks (the stars stay) and you can retry
## after a moment. The basic lens only reads common creatures; the upgraded one (the Gate Hall's stand) reads rare
## ones too (tamer.json "sync"). On success the creature dissolves into light, is synced to your team (up to three)
## or your Sanctuary, and the battle is won.

signal synced(rec: CreatureRecord)

const RING_R: float = 22.0
const RING_W: float = 3.0
const JOIN_LIFE: float = 0.5
const DEVICE := Vector2(10, 7)          ## the scanner held up beside the trainer (px)
const HAND := Vector2(9, -26)
const BEAM_W: float = 3.0
const SCAN_LINES: int = 3

var g: TamerGame
var tier: String = "basic"
var target: Creature
var progress: float = 0.0
var retry_t: float = 0.0                ## after a broken scan, F works again once this runs out
var _t: float = 0.0


func setup(game: TamerGame) -> void:
	g = game
	z_index = Fx.FX_Z
	material = Fx.glow_material()
	g.field.partner_changed.connect(_watch_partner)


func _watch_partner(c: Creature) -> void:
	if c != null and not c.struck.is_connected(_on_partner_hit):
		c.struck.connect(_on_partner_hit)


func S() -> Dictionary:
	return TamerData.rule("sync")


func lens() -> Dictionary:
	return S()["lenses"][tier]


func scanning() -> bool:
	return target != null and is_instance_valid(target)


## Is this creature being scanned right now (it struggles)?
func scanning_at(c: Creature) -> bool:
	return scanning() and target == c


## Can this creature be synced now (weakened, wild, not a trainer's)?
static func syncable(c: Creature) -> bool:
	return is_instance_valid(c) and c.alive() and c.catchable and c.side == Combatant.SIDE_WILD and c.dazed


## Can this lens read the creature's rarity?
func reads(c: Creature) -> bool:
	return (lens()["rarities"] as Array).has(String(c.rec.data().get("rarity", "common")))


## F in a battle: the scan starts on the opponent if it is weakened. Returns whether it started.
func request() -> bool:
	var c: Creature = g.battle.foe if g.battle.on else null
	if scanning():
		return false
	if retry_t > 0.0:
		g.hud.notice("The lens is recalibrating...")
		return false
	if c == null or not syncable(c):
		g.hud.notice("Weaken it first: the Sync Lens needs the gold stars (its life under the pink mark).")
		return false
	if not reads(c):
		g.hud.notice("Your %s can't read a rare creature. Upgrade it at the Gate Hall's lens stand." % lens()["name"])
		return false
	target = c
	progress = 0.0
	target.struck.connect(_on_target_hit)
	Audio.sfx("lamp_lit", -8.0, 1.3)
	TrainerShout.say("Sync Lens, lock on!")
	return true


func _process(delta: float) -> void:
	_t += delta
	retry_t = maxf(0.0, retry_t - delta)
	queue_redraw()
	if not scanning():
		target = null
		return
	if not syncable(target):
		cancel()
		return
	progress += delta * float(lens()["speed"]) / float(S()["scan"])
	if progress >= 1.0:
		_win(target)


func _on_target_hit(c: Creature, by: Combatant) -> void:
	if c == target and by != null and by.side == Combatant.SIDE_TEAM:
		_break("You hit it: the scan broke.")


func _on_partner_hit(_c: Creature, _by: Combatant) -> void:
	if scanning():
		_break("It struck your creature: the scan broke.")


## The scan breaks: the creature keeps its stars; F works again after a moment.
func _break(why: String) -> void:
	cancel()
	retry_t = float(S()["retry"])
	g.hud.notice(why + " Try again in a moment.")
	Audio.sfx("hiss", -8.0, 1.3)


func cancel() -> void:
	if target != null and is_instance_valid(target) and target.struck.is_connected(_on_target_hit):
		target.struck.disconnect(_on_target_hit)
	progress = 0.0
	target = null


## Synced: the creature dissolves into light that streams to the trainer's lens.
func _win(c: Creature) -> void:
	var rec: CreatureRecord = c.rec
	cancel()
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -12), 40, Vector2(40, 160), 0.8, TamerData.sparks(rec.element()), Vector2.UP)
	Fx.ring(g.fx_layer, c.global_position, 6.0, 60.0, Pal.c("glint"), 0.4)
	TamerFx.streak(c.global_position, g.trainer.global_position + HAND, rec.element())
	TamerFx.word(c.global_position, "Synced!", Pal.c("glint"), UiDraw.TITLE)
	Audio.sfx("lamp_lit", -4.0, 1.5)
	if rec.shiny:
		Fx.burst(g.fx_layer, c.global_position + Vector2(0, -16), 40, Vector2(60, 220), 0.9, [Pal.c("sun"), Pal.c("gold"), Pal.c("amber", 0.0)])
		Audio.sfx("lamp_lit", -2.0, 1.8)
	c.remove_from_group(Combatant.SIDE_WILD)
	c.fainted_now = true
	c.view.fade_out(0.5)
	c.get_tree().create_timer(0.5).timeout.connect(c.queue_free)
	rec.wild = false
	rec.life = rec.max_life() * JOIN_LIFE
	var to_party: bool = g.team.sync(rec)
	g.hud.notice(("%s joined your team!" if to_party else "%s was synced to your Sanctuary (camp).") % rec.display_name())
	synced.emit(rec)
	g.battle.synced(c)


## The scanner in the trainer's hand, the beam to the creature, scan lines and the filling ring.
func _draw() -> void:
	if not scanning():
		return
	var dev: Vector2 = g.trainer.global_position + HAND - global_position
	var to: Vector2 = target.global_position + Vector2(0, -10) - global_position
	draw_rect(Rect2(dev - DEVICE * 0.5, DEVICE), Pal.c("stone_lt"))
	draw_rect(Rect2(dev - DEVICE * 0.5, DEVICE), Pal.c("ink"), false, 1.0)
	draw_circle(dev + Vector2(2, 0), 2.5, Pal.c("glint"))
	draw_line(dev + Vector2(-3, 3), dev + Vector2(-3, 8), Pal.c("stone"), 2.0)
	var flick: float = 0.7 + 0.3 * sin(_t * 30.0)
	draw_line(dev, to, Pal.c("glint", 0.5 * flick), BEAM_W * 2.0)
	draw_line(dev, to, Pal.c("sun", flick), 1.0)
	for k: int in SCAN_LINES:
		var y: float = fmod(_t * 30.0 + k * 9.0, 26.0) - 13.0
		draw_line(to + Vector2(-12, y), to + Vector2(12, y), Pal.c("glint", 0.6), 1.0)
	draw_arc(to, RING_R, 0.0, TAU, 32, Color(Pal.c("ink"), 0.7), RING_W + 2.0)
	draw_arc(to, RING_R, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Pal.c("glint"), RING_W)
