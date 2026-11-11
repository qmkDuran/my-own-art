class_name BattleLauncher
extends RefCounted
## Starts battles from the overworld (tall-grass encounters and trainers), then handles what follows: a new
## friend, bond forms, a whiteout back at the Mender's, and any healing the battle set off.

const WHITEOUT_MAP: String = "mender"
const WHITEOUT_CELL: Vector2i = Vector2i(4, 4)

var world: Overworld
var current: BattleScene
## Battles started so far (click-to-walk stops when one interrupts it).
var started: int = 0


func _init(w: Overworld) -> void:
	world = w


func check_encounter() -> void:
	var enc: Dictionary = world.map.encounters
	if enc.is_empty() or not world.map.is_tall(world.player.cell) or Game.able_count() == 0:
		return
	if Game.rng.randf() >= float(enc["rate"]):
		return
	await wild_battle(roll_wild(enc))


func roll_wild(enc: Dictionary) -> Creature:
	var total: float = 0.0
	for e: Dictionary in enc["table"]:
		total += float(e["weight"])
	var pick: float = Game.rng.randf() * total
	for e: Dictionary in enc["table"]:
		pick -= float(e["weight"])
		if pick <= 0.0:
			return Creature.create(String(e["species"]), Game.rng.randi_range(int(e["min"]), int(e["max"])))
	return Creature.create(String(enc["table"][0]["species"]), int(enc["table"][0]["min"]))


func wild_battle(c: Creature) -> Dictionary:
	var foes: Array[Creature] = [c]
	return await _run("wild", "", foes)


func trainer_battle(id: String) -> Dictionary:
	var foes: Array[Creature] = []
	for entry: Array in Db.trainers[id]["team"]:
		foes.append(Creature.create(String(entry[0]), int(entry[1])))
	return await _run("trainer", id, foes)


func _run(kind: String, trainer: String, foes: Array[Creature]) -> Dictionary:
	var was_busy: bool = world.busy
	started += 1
	world.busy = true
	Audio.music("battle")
	Audio.sfx("encounter")
	await Fade.flash(world.ui)
	current = BattleScene.new()
	current.kind = kind
	current.trainer_id = trainer
	current.backdrop = world.map.battle_stage
	world.add_child(current)
	var result: Dictionary = await current.run(foes)
	await Fade.out(world.ui)
	current.queue_free()
	current = null
	Audio.music(world.map.music)
	await Fade.into(world.ui)
	await _aftermath(result)
	world.busy = was_busy
	return result


func _aftermath(result: Dictionary) -> void:
	if result.get("outcome", "") == "lose":
		await _whiteout()
		return
	await _evolutions()
	await world.healing.play_pending()


func _evolutions() -> void:
	for c: Creature in Game.party:
		var into: String = Bond.evolution_target(c)
		if into != "":
			var scene := EvolutionScene.new()
			world.ui.add_child(scene)
			await scene.run(c, into)
			scene.queue_free()


func _whiteout() -> void:
	await world.dialog.say(Db.lines("whiteout", Game.flags))
	Game.heal_party()
	Game.coins /= 2
	world.load_map(WHITEOUT_MAP, WHITEOUT_CELL, Vector2i.UP)
