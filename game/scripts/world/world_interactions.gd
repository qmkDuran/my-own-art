class_name WorldInteractions
extends RefCounted
## What happens when you press accept facing something, or walk into a trainer's sight: talking, signs, doors,
## counters you talk across, trainers who challenge you, and the story events those trigger.

const BEAT_FLAG: String = "beat_%s"

var world: Overworld
var events: StoryEvents


func _init(w: Overworld) -> void:
	world = w
	events = StoryEvents.new(w)


func is_shown(o: Dictionary) -> bool:
	return not (o.has("hide_flag") and Game.flags.get(String(o["hide_flag"]), false))


func interact() -> void:
	var ahead: Vector2i = world.player.cell + world.player.facing
	var npc: Walker = _npc_at(ahead)
	var thing: Dictionary = world.map.object_at(ahead, Game.heal_stage)
	if npc == null and thing.get("talk_through", false):
		npc = _npc_at(ahead + world.player.facing)
	if npc != null:
		await talk_to(npc)
	elif thing.has("talk"):
		await _read(thing)


func _npc_at(c: Vector2i) -> Walker:
	for w: Walker in world.npcs:
		if w.cell == c:
			return w
	return null


func _read(thing: Dictionary) -> void:
	world.busy = true
	await world.dialog.say(Db.lines(String(thing["talk"]), Game.flags))
	if thing.has("event"):
		await events.run(String(thing["event"]))
	world.busy = false


func talk_to(npc: Walker) -> void:
	world.busy = true
	npc.face(-world.player.facing)
	var o: Dictionary = world.npc_data[npc]
	if o["kind"] == "trainer":
		await _trainer_talk(npc, o)
	else:
		await world.dialog.say(Db.lines(String(o["talk"]), Game.flags), speaker(o))
		if o.has("event"):
			await events.run(String(o["event"]))
	world.busy = false


func speaker(o: Dictionary) -> String:
	return String(Db.people.get(String(o.get("person", "")), ""))


func _trainer_talk(npc: Walker, o: Dictionary) -> void:
	var t: Dictionary = Db.trainers[String(o["id"])]
	if Game.flags.get(BEAT_FLAG % o["id"], false):
		await world.dialog.say(PackedStringArray(t["after"]))
	else:
		await _challenge(npc, o)


## After every step: a trainer who can see you walks up and challenges you.
func check_trainers() -> bool:
	for npc: Walker in world.npcs:
		var o: Dictionary = world.npc_data[npc]
		if o["kind"] != "trainer" or Game.flags.get(BEAT_FLAG % o["id"], false):
			continue
		if _sees_player(npc, int(o.get("sight", 4))):
			world.busy = true
			await _approach(npc)
			await _challenge(npc, o)
			world.busy = false
			return true
	return false


func _sees_player(npc: Walker, sight: int) -> bool:
	var c: Vector2i = npc.cell
	for i: int in sight:
		c += npc.facing
		if c == world.player.cell:
			return true
		if not world.map.walkable(c, Game.heal_stage):
			return false
	return false


func _approach(npc: Walker) -> void:
	Audio.sfx("alert")
	await world.healing.exclaim(npc)
	while npc.cell + npc.facing != world.player.cell:
		await npc.step(npc.facing)
	world.player.face(-npc.facing)


func _challenge(npc: Walker, o: Dictionary) -> void:
	var id: String = String(o["id"])
	var t: Dictionary = Db.trainers[id]
	await world.dialog.say(PackedStringArray(t["intro"]))
	var result: Dictionary = await world.battles.trainer_battle(id)
	if result.get("outcome", "") == "win":
		Game.flags[BEAT_FLAG % id] = true
		Game.coins += int(t["reward"])
		await world.dialog.say(PackedStringArray(t["defeat"]) + PackedStringArray(
			["You received %d coins." % int(t["reward"])]))
	npc.face(MapGrid.dir_of(String(o.get("facing", "down"))))


func open_menu() -> void:
	world.busy = true
	var menu := PauseMenu.new()
	world.ui.add_child(menu)
	await menu.run(world)
	menu.queue_free()
	world.busy = false
