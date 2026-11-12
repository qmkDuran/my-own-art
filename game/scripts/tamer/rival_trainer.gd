class_name RivalTrainer
extends Node2D
## A rival trainer standing on the route (tamer.json "battle.trainers"). Come close and they ask "Want to battle?"
## (Accept or Decline, never forced; decline and they ask again only after you have walked away). Accept and it is
## a 3v3 in an arena (OpponentTrainer); win and they remember it.

const COLS: int = 8
const FPS: float = 8.0
const ASK_RANGE: float = 120.0
const ASK_AGAIN: float = 260.0
const ROOM: float = 10.0
const CLEAR: float = 300.0

var g: TamerGame
var data: Dictionary
var opponent: OpponentTrainer
var beaten: bool = false
var sprite: Sprite2D
var _asked: bool = false
var _t: float = 0.0


func setup(game: TamerGame, d: Dictionary, at: Vector2) -> RivalTrainer:
	g = game
	data = d
	position = at
	add_child(PropSprite.shadow(22.0))
	sprite = Sprite2D.new()
	sprite.texture = PropSprite.tex("res://art/creatures/%s.png" % d["sprite"])
	sprite.hframes = COLS
	sprite.vframes = 2
	sprite.offset = Vector2(0, -29)
	add_child(sprite)
	return self


func display_name() -> String:
	return String(data["name"])


func _process(delta: float) -> void:
	_t += delta
	sprite.frame = int(_t * FPS) % COLS
	var d: float = global_position.distance_to(g.trainer.global_position)
	sprite.flip_h = g.trainer.global_position.x < global_position.x
	if _asked and d > ASK_AGAIN:
		_asked = false
	if not _asked and not g.battle.on and not g.transition.busy and d < ASK_RANGE and g.field.partner != null:
		_ask()


func _ask() -> void:
	_asked = true
	g.trainer.stop()
	var lines: Dictionary = data["lines"]
	g.hud.ask(String(lines["ask"]), accept, func() -> void: g.hud.caption(String(lines["decline"])))


func accept() -> void:
	var level: int = g.team.current().level if g.team.current() != null else 5
	opponent = OpponentTrainer.new().setup(data, level, String(data["tier"]))
	g.battle.start_trainer(opponent, String(TamerData.rule("battle.route_arena")))


## The battle is over: a win is remembered (and rewarded once), a loss is just a "come back".
func finish(won_by_player: bool) -> void:
	var lines: Dictionary = data["lines"]
	g.hud.caption(String(lines["win"] if won_by_player else lines["lose"]))
	if won_by_player and not beaten:
		beaten = true
		for id: String in data["reward"]:
			g.team.add_material(id, int(data["reward"][id]))
