class_name TeamField
extends Node
## Puts your active creature on the field and takes it back: swapping (1-3) calls the new one out with a small
## entry attack; a knocked-out creature fades away and the next one that can fight steps in; one that recovers
## comes back to your side; with none left the trainer retreats to camp (TamerGame.white_out). A swap timed just
## before a wild attack lands is a perfect swap. Items (4, 5) heal or wake your creatures. Bond milestones here.

signal swapped(rec: CreatureRecord)
signal partner_changed(c: Creature)

const ENTRY_SPOT := Vector2(26, 10)
const AUTO_SWAP_DELAY: float = 0.8
const SWAP_COOLDOWN: float = 0.5
const RECALL_TIME: float = 0.25

var g: TamerGame
var partner: Creature
var _swap_cd: float = 0.0
var _auto_t: float = -1.0


func setup(game: TamerGame) -> void:
	g = game
	g.team.bond_unlocked.connect(_on_bond)


## Calls member `i` out beside the trainer; with `entry`, it strikes as it lands.
func summon(i: int, entry: bool, perfect: bool = false) -> void:
	var rec: CreatureRecord = g.team.members[i]
	g.team.set_active(i)
	var c := Creature.new().setup(rec, Combatant.SIDE_TEAM)
	var side: float = -1.0 if g.trainer.heading.x > 0.0 else 1.0
	c.position = g.layout.free_spot_near(g.trainer.global_position + ENTRY_SPOT * Vector2(side, 1.0), rec.radius())
	c.brain = PartnerBrain.new(c)
	c.fainted.connect(_on_knocked_out)
	g.world.add_child(c)
	c.add_to_group(TreeFade.FOCUS)
	partner = c
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -12), 22, Vector2(50, 160), 0.45, TamerData.sparks(rec.element()))
	Fx.ring(g.fx_layer, c.global_position, 6.0, 46.0, TamerData.color(rec.element(), "light"), 0.3)
	if entry:
		_entry_attack(c, perfect)
	partner_changed.emit(c)


func _entry_attack(c: Creature, perfect: bool) -> void:
	var E: Dictionary = TamerData.rule("entry")
	var k: float = float(TamerData.rule("perfect_swap.mult")) if perfect else 1.0
	var m: Dictionary = {"name": "Entry", "damage": float(E["damage"]) * k, "stun": float(E["stun"]) * k, "knock": 14.0}
	TamerFx.blast(c.global_position, float(E["radius"]), c.element_id(), true)
	var call: String = "Perfect swap! Go, %s!" if perfect else "Go, %s!"
	TamerFx.word(c.global_position, call % c.rec.data()["name"], Pal.c("gold") if perfect else TamerData.color(c.element_id(), "light"), UiDraw.TITLE)
	if perfect:
		Fx.screen_flash(Pal.c("gold"), 0.2, 0.3)
	Audio.sfx("slam", -6.0, 1.1)
	for f: Combatant in MoveKind.foes_in(c, c.global_position, float(E["radius"])):
		CreatureCombat.hit(c, f, m, (f.global_position - c.global_position).normalized())


## 1-3: swap to member `i` (not to one that is knocked out).
func swap(i: int) -> bool:
	if _swap_cd > 0.0 or not g.team.can_swap_to(i):
		return false
	_swap_cd = SWAP_COOLDOWN
	var perfect: bool = _dodge_incoming()
	recall()
	summon(i, true, perfect)
	swapped.emit(g.team.members[i])
	return true


## Swapping just as a wild attack is about to land on your creature: the attack whiffs and the swap-in hits twice
## as hard (perfect_swap.window seconds before it lands).
func _dodge_incoming() -> bool:
	if partner == null:
		return false
	var perfect: bool = false
	for n: Node in get_tree().get_nodes_in_group(Combatant.SIDE_WILD):
		var b := (n as Creature).brain as WildBrain
		if b != null and b.winding_at(partner) and b.windup_left() <= float(TamerData.rule("perfect_swap.window")):
			b.cancel_windup()
			perfect = true
	return perfect


## Takes the partner off the field (it keeps its record: life, bond, cooldowns start fresh).
func recall() -> void:
	if partner == null or not is_instance_valid(partner):
		partner = null
		return
	var c: Creature = partner
	partner = null
	c.remove_from_group(Combatant.SIDE_TEAM)
	c.remove_from_group(TreeFade.FOCUS)
	c.fainted_now = true
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -12), 14, Vector2(40, 120), 0.35, TamerData.sparks(c.element_id()), Vector2.UP)
	c.view.fade_out(RECALL_TIME)
	get_tree().create_timer(RECALL_TIME).timeout.connect(c.queue_free)
	partner_changed.emit(null)


func _on_knocked_out(c: Creature) -> void:
	c.rec.knock_out()
	partner = null
	partner_changed.emit(null)
	g.hud.notice("%s is knocked out! It will recover in a while, or at camp." % c.rec.data()["name"])
	_auto_t = AUTO_SWAP_DELAY


func _process(delta: float) -> void:
	g.team.tick(delta)
	_swap_cd -= delta
	if _auto_t > 0.0:
		_auto_t -= delta
		if _auto_t <= 0.0:
			_step_in()
	elif partner == null and g.team.current() != null and not g.retreating:
		if not g.team.current().knocked_out():
			summon(g.team.active, false)                 # it recovered and comes back to your side
		elif g.team.next_awake() >= 0:
			_step_in()


func _step_in() -> void:
	var i: int = g.team.next_awake()
	if i >= 0:
		summon(i, true)
	elif not g.retreating:
		g.white_out()


func use_item(id: String) -> bool:
	var rec: CreatureRecord = g.team.current()
	if rec == null:
		return false
	var it: Dictionary = TamerData.rule("items." + id)
	if it.has("heal") and (rec.knocked_out() or rec.life_frac() >= 1.0):
		return false
	if it.has("revive"):
		rec = _first_out()
		if rec == null:
			return false
	if not g.team.use_item(id):
		g.hud.notice("No %s left" % it["name"])
		return false
	if it.has("heal"):
		rec.heal(float(it["heal"]))
	else:
		rec.revive(float(it["revive"]))
	Audio.sfx("tonic", -6.0)
	if partner != null:
		Fx.burst(g.fx_layer, partner.global_position + Vector2(0, -12), 18, Vector2(30, 90), 0.6, [Pal.c("sun"), Pal.c("leaf_lt"), Pal.c("leaf", 0.0)], Vector2.UP)
	return true


func _first_out() -> CreatureRecord:
	if g.team.current().knocked_out():
		return g.team.current()
	for r: CreatureRecord in g.team.members:
		if r.knocked_out():
			return r
	return null


func _on_bond(rec: CreatureRecord) -> void:
	var who: Node2D = partner if partner != null and partner.rec == rec else g.trainer
	TamerFx.celebrate(who, rec.element())
	TamerFx.word(who.global_position, "Bond!", Pal.c("rose"), UiDraw.TITLE)
	g.hud.notice("Your bond with %s grew! It learned %s (T)." % [rec.data()["name"], TamerData.move(rec.bond_move())["name"]])
	g.guide.done("bond")
