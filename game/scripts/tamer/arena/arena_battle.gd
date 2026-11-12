class_name ArenaBattle
extends Node
## A battle, 1v1 at a time, in its own walled arena (Arena). It starts with the swirl transition from wherever you
## were (the route, the Gate Hall), puts your creature on the left and the opponent's on the right, both trainers
## watching from outside the walls, and gives you control of your creature. A wild battle ends when the creature
## faints or is synced; a trainer battle when all three of theirs are down. Then XP and materials, a Victory card,
## and the transition back to the exact spot you left. Your team wiped: you lose (the white-out).

const ARENA_ORIGIN := Vector2(-6000, 0)
const DECIDE_EVERY: float = 0.5

var g: TamerGame
var on: bool = false
var arena: Arena
var opponent: OpponentTrainer           ## null in a wild battle
var foe: Creature
var tier_id: String = "normal"
var route_creature: Creature            ## the wild one you walked into (it leaves the route if you win or sync it)
var _back_area: String = ""
var _back_at: Vector2
var _decide_t: float = 0.0
var _send_t: float = -1.0
var _wild_rec: CreatureRecord
var _defeated: int = 0
var _materials: Dictionary = {}


func setup(game: TamerGame) -> void:
	g = game


func start_wild(rec: CreatureRecord, arena_id: String, tier: String, from_route: Creature = null) -> void:
	_wild_rec = rec
	opponent = null
	route_creature = from_route
	_begin(arena_id, tier)


func start_trainer(trainer: OpponentTrainer, arena_id: String) -> void:
	opponent = trainer
	_wild_rec = null
	route_creature = null
	_begin(arena_id, trainer.tier_id)


func _begin(arena_id: String, tier: String) -> void:
	if on or g.transition.busy or g.field.partner == null:
		return
	on = true
	tier_id = tier
	_defeated = 0
	_materials = g.team.materials.duplicate()
	_back_area = g.area
	_back_at = g.trainer.global_position
	g.transition.play(func() -> void: _enter(arena_id))


func _enter(arena_id: String) -> void:
	arena = Arena.new().build(arena_id, ARENA_ORIGIN, g.hall.size_id)
	g.add_child(arena)
	g.enter_arena(arena)
	g.trainer.place(arena.trainer_spot(true))
	g.field.summon_at(g.team.active, arena.you_spot(), false)
	if opponent != null:
		opponent.stand_at = arena.trainer_spot(false) + Vector2(0, -20)
		_stand_in(String(opponent.data.get("sprite", "rival_ivo")), arena.trainer_spot(false))
		_send(opponent.best_against(g.field.partner))
	else:
		_send(_wild_rec)


## A creature of theirs comes out on the right. A trainer's keeps the gauge its team has built (as yours does),
## and one that comes in after a swap or a knock-out strikes as it lands (as yours does).
func _send(rec: CreatureRecord, entry: bool = false) -> void:
	var gauge: float = foe.gauge if foe != null and is_instance_valid(foe) else 0.0
	foe = Creature.new().setup(rec, Combatant.SIDE_WILD)
	foe.gauge = gauge
	foe.position = arena.layout.free_spot_near(arena.foe_spot(), rec.radius())
	foe.catchable = opponent == null
	foe.brain = FoeBrain.new(foe, tier_id)
	foe.fainted.connect(_on_foe_down)
	arena.stage.add_child(foe)
	CreatureTag.attach(foe)
	if opponent != null:
		opponent.active = foe
	if entry:
		CreatureCombat.entry(foe)
	else:
		TamerFx.blast(foe.global_position, 46.0, rec.element(), true)


func _on_foe_down(c: Creature) -> void:
	_defeated += 1
	g.team.current().growth.add_xp(float(TamerData.rule("progression.trainer_win_xp" if opponent != null else "progression.win_xp")))
	var span: Array = TamerData.rule("battle.rewards.materials")
	var got: int = randi_range(int(span[0]), int(span[1]))
	g.team.add_material(String(c.rec.data()["material"]), got)
	TamerFx.word(c.global_position, "+%d %s" % [got, TamerData.rule("materials." + String(c.rec.data()["material"]) + ".name")], Pal.c("gold"))
	if opponent != null and opponent.has_more():
		_send_t = float(TamerData.rule("combat.step_in_delay"))
	else:
		end(true)


## Synced in battle: the battle is won.
func synced(c: Creature) -> void:
	if on and c == foe:
		_defeated += 1
		end(true)


func _process(delta: float) -> void:
	if not on or arena == null or g.transition.busy:
		return
	if _send_t > 0.0:
		_send_t -= delta
		if _send_t <= 0.0:
			_send(opponent.best_against(g.field.partner), true)
		return
	_decide_t -= delta
	if opponent != null and _decide_t <= 0.0:
		_decide_t = DECIDE_EVERY
		var swap: CreatureRecord = opponent.decide(g.field.partner)
		if swap != null:
			_swap_foe(swap)


## The opposing trainer swaps by your rules: a gauge segment and the swap cooldown (OpponentTrainer.decide).
func _swap_foe(swap: CreatureRecord) -> void:
	TamerFx.word(opponent.stand_at, "Come back, %s! Go, %s!" % [foe.rec.display_name(), swap.display_name()], Pal.c("rose"))
	foe.gauge = maxf(0.0, foe.gauge - float(TamerData.rule("combat.gauge.swap_cost")))
	foe.fainted.disconnect(_on_foe_down)
	foe.recall_quietly()
	_send(swap, true)


func end(won: bool) -> void:
	if not on:
		return
	if won:
		TrainerShout.moment("win")
	on = false
	g.field.release_control()
	if won:
		g.hud.victory(_summary())
		g.guide.done("win")
		if route_creature != null and is_instance_valid(route_creature):
			route_creature.queue_free()
	if opponent != null:
		g.battle_over_with_trainer(opponent, won)
	g.transition.play(_leave)


func _leave() -> void:
	if foe != null and is_instance_valid(foe) and not foe.fainted_now:
		foe.recall_quietly()
	g.return_to(_back_area, _back_at)
	arena.queue_free()
	arena = null


## The opposing trainer, watching from outside the right wall.
func _stand_in(sprite: String, at: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = PropSprite.tex("res://art/creatures/%s.png" % sprite)
	s.hframes = Trainer.COLS
	s.vframes = 2
	s.offset = Vector2(0, -29)
	s.flip_h = true
	s.position = at
	arena.stage.add_child(s)


func _summary() -> Array[String]:
	var rec: CreatureRecord = g.team.current()
	var out: Array[String] = ["Defeated %d" % _defeated, "%s  Lv %d" % [rec.display_name(), rec.level]]
	for id: String in g.team.materials:
		var gained: int = g.team.count(id) - int(_materials.get(id, 0))
		if gained > 0:
			out.append("+%d %s" % [gained, TamerData.rule("materials." + id + ".name")])
	return out
