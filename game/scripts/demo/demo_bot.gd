class_name DemoBot
extends Node
## Plays like a player for the recorded videos, through the same input paths (a virtual cursor, clicks, skill
## keys): lashes the nearest enemy, uses Flare in a crowd, Moth Swarm at range, Lantern Toss at a pack when the
## light is high, steps out of warning circles, drinks tonics, picks up good loot, reads dialogue at a calm pace.
## Follows whichever zone is being played (it lives under the test runner, so zone changes don't end it).

const THINK: float = 0.12
const SIGHT: float = 420.0
const LOOT_RANGE: float = 200.0
const DODGE: float = 140.0
const READ_LINE: float = 1.4
const TOSS_LIGHT: float = 50.0

var g: Game
var _think: float = 0.0
var _read_t: float = 0.0


func _physics_process(delta: float) -> void:
	g = Game.current
	if g == null:
		return
	_think -= delta
	if _think <= 0.0:
		_think = THINK
		_decide()


## One decision: drink, dash, a big skill if it fits the moment, else lash the nearest enemy; loot when calm.
func _decide() -> void:
	var p: Player = g.player
	if g.hud.messages.modal() and not g.hud.messages.end_card:
		_read_t += THINK
		if _read_t >= READ_LINE:
			_read_t = 0.0
			g.hud.messages.advance()
		return
	if p.dead or g.ui.blocking():
		g.input.lmb_held = false
		return
	var foes: Array[Enemy] = _foes()
	if foes.is_empty():
		g.input.lmb_held = false
		_calm()
		return
	var e: Enemy = foes[0]
	var d: float = p.global_position.distance_to(e.global_position)
	if p.life < p.stats.max_life() * 0.5:
		p.drink_tonic()
	if _dodge():
		return
	if _try_skill(foes, e, d):
		return
	g.input.cursor_override = e.global_position + Vector2(0, -12)
	if not g.input.lmb_held:
		g.input.press()


## Step out of a warning circle (away from its centre) if Wickstep is ready.
func _dodge() -> bool:
	for n: Node in get_tree().get_nodes_in_group("telegraphs"):
		var t := n as Telegraph
		if t.covers(g.player.global_position) and g.player.dash_cooldown().x <= 0.0:
			var away: Vector2 = (g.player.global_position - t.global_position).normalized()
			if t.lane != Vector2.ZERO:
				away = t.lane.normalized().orthogonal()
			if away == Vector2.ZERO:
				away = Vector2.DOWN
			g.input.lmb_held = false
			return g.player.dash(g.player.global_position + away * DODGE)
	return false


func _foes() -> Array[Enemy]:
	var out: Array[Enemy] = []
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if not e.dead and e.global_position.distance_to(g.player.global_position) < SIGHT:
			out.append(e)
	out.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(g.player.global_position) < b.global_position.distance_squared_to(g.player.global_position))
	return out


func _try_skill(foes: Array[Enemy], e: Enemy, d: float) -> bool:
	var s: SkillSystem = g.player.skills
	var flare_r: float = (s.skill("flare") as Flare).radius()
	var close: int = foes.filter(func(f: Enemy) -> bool: return f.global_position.distance_to(g.player.global_position) < flare_r).size()
	var key: String = ""
	if close >= 3 and s.block("flare") == "":
		key = "rmb"
	elif d > 130.0 and d < 300.0 and foes.size() >= 3 and g.player.light.value > TOSS_LIGHT and s.block("lantern_toss") == "" \
			and not (s.skill("lantern_toss") as LanternToss).away():
		key = "q"
	elif d > 90.0 and d < 280.0 and s.block("moth_swarm") == "":
		key = "w"
	if key == "":
		return false
	g.input.lmb_held = false
	g.input.cursor_override = e.global_position
	return g.input.use_slot(key)


## Nothing to fight: pick up good loot nearby, talk to Nim once the Glazier is down.
func _calm() -> void:
	for n: Node in get_tree().get_nodes_in_group("ground_items"):
		var gi := n as GroundItem
		if gi.global_position.distance_to(g.player.global_position) < LOOT_RANGE and gi.item["rarity"] != "normal":
			g.input.cursor_override = gi.label_rect().get_center()
			g.input.press()
			g.input.lmb_held = false
			return
	if g.flags.has("nim_free") and not g.flags.has("slice_done"):
		for n: Node in get_tree().get_nodes_in_group("interactables"):
			if n is Npc and (n as Npc).npc_id == "nim":
				(n as Npc).use(g)
				return
