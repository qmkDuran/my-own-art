class_name TrainerShout
extends RefCounted
## The trainer's voice from the arena edge: "Come back, X! Go, Y!" on a swap, and short shouts on big moments (a
## stagger, your creature in trouble, a win) from tamer.json "trainer_shouts", at most one every `gap`
## seconds. Flavour only.

static var _last: float = -100.0


## A shout for a moment ("staggered", "low", "win"), unless one was heard just now.
static func moment(kind: String) -> void:
	var S: Dictionary = TamerData.rule("trainer_shouts")
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last < float(S["gap"]):
		return
	var lines: Array = S[kind]
	say(String(lines[randi() % lines.size()]))


static func swap(out_name: String, in_name: String) -> void:
	say("Come back, %s! Go, %s!" % [out_name, in_name])


static func say(text: String) -> void:
	var g: TamerGame = TamerGame.current
	if g == null or not g.battle.on:
		return
	_last = Time.get_ticks_msec() / 1000.0
	TamerFx.word(g.trainer.global_position + Vector2(0, -20), text, Pal.c("bone"))
