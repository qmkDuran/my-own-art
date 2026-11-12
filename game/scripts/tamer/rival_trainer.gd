class_name RivalTrainer
extends Node2D
## A rival trainer standing on the route (tamer.json "rivals"). When you come into sight they walk up, say their
## line, and battle: their creatures come out one at a time inside the battle ring and fight with their species'
## style. The rival is never hurt (stays behind, like you) and thinks as a trainer: sends the next creature when one
## falls, swaps out of an element disadvantage or at low life, and uses a heal once. Beat every creature to win.

signal defeated(r: RivalTrainer)

const COLS: int = 8
const FPS: float = 8.0
const WALK: float = 120.0

var g: TamerGame
var data: Dictionary
var team: Array[CreatureRecord] = []
var active: Creature
var state: String = "waiting"           ## waiting, talking, battling, beaten
var home: Vector2
var _t: float = 0.0
var _item_used: bool = false
var _swapped: Dictionary = {}           ## record -> true once it has been swapped out
var sprite: Sprite2D


func setup(game: TamerGame, d: Dictionary, at: Vector2) -> RivalTrainer:
	g = game
	data = d
	position = at
	home = at
	_make_team()
	add_child(PropSprite.shadow(22.0))
	sprite = Sprite2D.new()
	sprite.texture = PropSprite.tex("res://art/creatures/%s.png" % d["sprite"])
	sprite.hframes = COLS
	sprite.vframes = 2
	sprite.offset = Vector2(0, -32 + 3)
	sprite.flip_h = true
	add_child(sprite)
	return self


func R() -> Dictionary:
	return TamerData.rule("rivals")


func _make_team() -> void:
	team.clear()
	for e: Array in data["team"]:
		var r := CreatureRecord.make(String(e[0]), int(e[1]), true)
		r.life_boost = float(R()["life_mult"])
		r.power_boost = float(R()["power_mult"])
		r.life = r.max_life()
		team.append(r)
	_item_used = false
	_swapped.clear()


func display_name() -> String:
	return String(data["name"])


func has_more() -> bool:
	return team.any(func(r: CreatureRecord) -> bool: return r.life > 0.0)


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = (COLS if state == "talking" and global_position.distance_to(g.trainer.global_position) > float(R()["walk_up"]) else 0) + int(_t * FPS) % COLS
	match state:
		"waiting":
			if not g.battle.on and g.battle.may_join(null) and g.field.partner != null and \
					global_position.distance_to(g.trainer.global_position) < float(R()["spot_range"]):
				_spot()
		"talking":
			_walk_up(delta)
		"battling":
			_think()


func _spot() -> void:
	state = "talking"
	_t = 0.0
	g.trainer.stop()
	g.hud.caption(String(data["spot"]))
	TamerFx.word(global_position, "!", Pal.c("gold"), UiDraw.TITLE)
	Audio.sfx("ui_open", -4.0, 1.4)


func _walk_up(delta: float) -> void:
	var to: Vector2 = g.trainer.global_position
	if global_position.distance_to(to) > float(R()["walk_up"]):
		global_position = global_position.move_toward(to, WALK * delta)
		sprite.flip_h = to.x < global_position.x
	elif _t > float(R()["talk_time"]):
		_begin()


func _begin() -> void:
	state = "battling"
	_make_team()
	active = _send(_best_against(g.field.partner))
	g.battle.engage_rival(self, active)


## The rival's creature comes out next to their side of the ring, with a word.
func _send(rec: CreatureRecord) -> Creature:
	var at: Vector2 = g.layout.free_spot_near(global_position.lerp(g.field.partner.global_position, 0.4), rec.radius())
	var c: Creature = g.spawner.spawn(rec.species_id, at, rec.level, -1, 0)
	c.rec = rec
	c.catchable = false
	TamerFx.word(c.global_position, "%s: Go, %s!" % [display_name(), rec.data()["name"]], Pal.c("rose"), UiDraw.BODY)
	TamerFx.blast(c.global_position, 50.0, rec.element(), true)
	if g.battle.on:
		g.battle.add_fighter(c)
	return c


## A record that is still standing, preferring one whose element beats your creature's (and never one it beats).
func _best_against(p: Creature) -> CreatureRecord:
	var best: CreatureRecord = null
	var best_score: float = -INF
	for r: CreatureRecord in team:
		if r.life <= 0.0 or (active != null and is_instance_valid(active) and r == active.rec):
			continue
		var score: float = r.life_frac()
		if p != null:
			score += float(TamerData.matchup(r.element(), p.element_id())) - float(TamerData.matchup(p.element_id(), r.element()))
		if score > best_score:
			best_score = score
			best = r
	return best


## Between blows: the next creature when one falls, a smart swap, the one heal.
func _think() -> void:
	if not g.battle.on:
		return
	if active == null or not is_instance_valid(active) or active.fainted_now:
		if _t > float(R()["send_delay"]) and has_more():
			var next: CreatureRecord = _best_against(g.field.partner)
			if next != null:
				active = _send(next)
		return
	_t = 0.0
	var life: float = active.rec.life_frac()
	if not _item_used and life < float(R()["item_below"]):
		_item_used = true
		active.rec.life = minf(active.rec.max_life(), active.rec.life + active.rec.max_life() * float(R()["item_heal"]))
		TamerFx.word(active.global_position, "%s used a Honeyberry!" % display_name(), Pal.c("leaf_lt"))
		Audio.sfx("tonic", -6.0)
	elif _should_swap(life):
		_swap_out()


func _should_swap(life: float) -> bool:
	if _swapped.has(active.rec) or g.field.partner == null:
		return false
	var losing: bool = TamerData.matchup(g.field.partner.element_id(), active.element_id()) == TamerData.SUPER
	return (losing or life < float(R()["swap_below"])) and _best_against(g.field.partner) != null


func _swap_out() -> void:
	_swapped[active.rec] = true
	var next: CreatureRecord = _best_against(g.field.partner)
	g.battle.remove_fighter(active)
	TamerFx.word(active.global_position, "%s: Come back!" % display_name(), Pal.c("rose"))
	active.recall_quietly()
	active = _send(next)


## The battle is over: beaten, or (if your team was wiped) back to waiting at full strength.
func finish(won_by_player: bool) -> void:
	if active != null and is_instance_valid(active) and not active.fainted_now:
		active.recall_quietly()
	active = null
	if won_by_player:
		state = "beaten"
		g.hud.caption(String(data["win"]))
		for id: String in data["reward"]:
			g.team.add_material(id, int(data["reward"][id]))
		defeated.emit(self)
	else:
		state = "waiting"
		global_position = home
		g.hud.caption(String(data["lose"]))
