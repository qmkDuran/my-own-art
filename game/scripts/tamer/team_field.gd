class_name TeamField
extends Node
## Puts your active creature on the field and takes it back. Outside battle it follows you and swapping (1-3) is
## free; in battle you control it (ControlledBrain), a swap costs a gauge segment and has a cooldown, and the
## swap-in strikes as it lands. A knocked-out creature fades away and the next one steps in; with none left you
## lose (TamerGame.team_wiped). Items (Z, V) only work outside battle. Level-ups and the evolution show here.

signal partner_changed(c: Creature)

const ENTRY_SPOT := Vector2(26, 10)
const AUTO_SWAP_DELAY: float = 0.8
const SWAP_COOLDOWN_OUT: float = 0.5
const RECALL_TIME: float = 0.25

var g: TamerGame
var partner: Creature
var _swap_cd: float = 0.0
var _auto_t: float = -1.0


func setup(game: TamerGame) -> void:
	g = game
	g.team.leveled.connect(_on_leveled)
	g.team.evolved.connect(_on_evolved)


## Level up: a word over it and a notice for each move it learned.
func _on_leveled(rec: CreatureRecord) -> void:
	var who: Node2D = partner if partner != null and is_instance_valid(partner) and partner.rec == rec else g.trainer
	TamerFx.word(who.global_position, "Lv %d!" % rec.level, Pal.c("sun"), UiDraw.TITLE)
	Audio.sfx("level_up", -6.0)
	for id: String in rec.growth.learned_at(rec.level):
		g.hud.notice("%s learned %s! (choose its moves at camp or the Gate Hall's station)" % [rec.display_name(), TamerData.move(id)["name"]])


func _on_evolved(rec: CreatureRecord) -> void:
	if partner != null and is_instance_valid(partner) and partner.rec == rec:
		EvolutionCeremony.play(partner)
	else:
		g.hud.notice("%s evolved into %s!" % [rec.data()["name"], rec.display_name()])


## Calls member `i` out where the last one stood, or beside the trainer (in an arena, at your start spot); with
## `entry`, it strikes as it lands.
func summon(i: int, entry: bool) -> void:
	var side: float = -1.0 if g.trainer.heading.x > 0.0 else 1.0
	var at: Vector2 = g.trainer.global_position + ENTRY_SPOT * Vector2(side, 1.0)
	if partner != null and is_instance_valid(partner):
		at = partner.global_position
	elif g.battle.on and g.battle.arena != null:
		at = g.battle.arena.you_spot()
	summon_at(i, at, entry)


## Calls member `i` out at `at` (in battle, under your control).
func summon_at(i: int, at: Vector2, entry: bool) -> void:
	var rec: CreatureRecord = g.team.members[i]
	g.team.set_active(i)
	var c := Creature.new().setup(rec, Combatant.SIDE_TEAM)
	c.position = g.layout.free_spot_near(at, rec.radius())
	c.brain = ControlledBrain.new(c) if g.battle.on else PartnerBrain.new(c)
	c.fainted.connect(_on_knocked_out)
	g.world.add_child(c)
	CreatureTag.attach(c)
	c.view.set_highlight(g.battle.on)
	c.add_to_group(TreeFade.FOCUS)
	partner = c
	Fx.burst(g.fx_layer, c.global_position + Vector2(0, -12), 22, Vector2(50, 160), 0.45, TamerData.sparks(rec.element()))
	Fx.ring(g.fx_layer, c.global_position, 6.0, 46.0, TamerData.color(rec.element(), "light"), 0.3)
	if entry:
		_entry_attack(c)
	partner_changed.emit(c)


func _entry_attack(c: Creature) -> void:
	var E: Dictionary = TamerData.rule("entry")
	var m: Dictionary = {"name": "Entry", "type": "special", "damage": float(E["damage"]), "stun": float(E["stun"]), "knock": 14.0,
		"stagger": float(TamerData.rule("combat.stagger.entry")) / float(E["damage"])}
	TamerFx.blast(c.global_position, float(E["radius"]), c.element_id(), true)
	TamerFx.word(c.global_position, "Go, %s!" % c.rec.display_name(), TamerData.color(c.element_id(), "light"), UiDraw.TITLE)
	Audio.sfx("slam", -6.0, 1.1)
	for f: Combatant in MoveKind.foes_in(c, c.global_position, float(E["radius"])):
		CreatureCombat.hit(c, f, m, (f.global_position - c.global_position).normalized())


func release_control() -> void:
	if partner != null and is_instance_valid(partner):
		partner.brain = PartnerBrain.new(partner)
		partner.view.set_highlight(false)


func swap_cooldown_left() -> float:
	return maxf(0.0, _swap_cd)


## 1-6: swap to member `i` (not to one that is knocked out). In battle it costs gauge and has a cooldown.
func swap(i: int) -> bool:
	if _swap_cd > 0.0 or not g.team.can_swap_to(i):
		return false
	if g.battle.on and not g.team.spend_gauge(int(TamerData.rule("combat.gauge.swap_cost"))):
		g.hud.gauge_short(int(TamerData.rule("combat.gauge.swap_cost")))
		return false
	_swap_cd = float(TamerData.rule("combat.swap_cooldown")) if g.battle.on else SWAP_COOLDOWN_OUT
	recall()
	summon(i, g.battle.on)
	return true


## Gone at once (moving between places).
func recall_now() -> void:
	if partner != null and is_instance_valid(partner):
		partner.queue_free()
	partner = null


## Takes the partner off the field (it keeps its record: life; cooldowns and effects start fresh).
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
	g.hud.notice("%s is knocked out!" % c.rec.data()["name"])
	_auto_t = AUTO_SWAP_DELAY


func _process(delta: float) -> void:
	if not g.battle.on:
		g.team.tick(delta)                                # knock-outs recover over time, but not mid-battle
	_swap_cd -= delta
	if _auto_t > 0.0:
		_auto_t -= delta
		if _auto_t <= 0.0:
			_step_in()
	elif partner == null and g.team.current() != null and not g.retreating and not g.transition.busy:
		if not g.team.current().knocked_out():
			summon(g.team.active, false)                 # it recovered and comes back to your side
		elif g.team.next_awake() >= 0:
			_step_in()


func _step_in() -> void:
	var i: int = g.team.next_awake()
	if i >= 0:
		summon(i, true)
	elif not g.retreating:
		g.team_wiped()


func use_item(id: String) -> bool:
	var rec: CreatureRecord = g.team.current()
	if rec == null:
		return false
	if g.battle.on:
		g.hud.notice("No items in battle")
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

