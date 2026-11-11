class_name StoryEvents
extends RefCounted
## Story events named in map data ("event": ...): the Mender's healing, Pell's shop, Gran's first talk, and
## waking the Wellspring.

var world: Overworld

const GRAN_GIFT: Dictionary = {"sunberry": 3, "smoky_nut": 2, "sweet_kelp": 2, "mending_salve": 2}
const GRAN_COINS: int = 100


func _init(w: Overworld) -> void:
	world = w


func run(event: String) -> void:
	match event:
		"heal":
			await _heal()
		"shop":
			await _shop()
		"gran":
			await _gran()
		"wellspring":
			await _wellspring()


func _heal() -> void:
	Game.heal_party()
	Audio.sfx("heal")
	await world.healing.sparkle_on(world.player)


func _shop() -> void:
	var shop := ShopPanel.new()
	world.ui.add_child(shop)
	await shop.run()
	shop.queue_free()
	await world.dialog.say(Db.lines("grocer_bye", Game.flags), "Pell")


func _gran() -> void:
	if Game.flags.get("met_gran", false):
		return
	for id: String in GRAN_GIFT:
		Game.bag.add(id, int(GRAN_GIFT[id]))
	Game.coins += GRAN_COINS
	Audio.sfx("jingle")
	await world.dialog.say(PackedStringArray(["You received treats, salves and %d coins!" % GRAN_COINS]))
	Game.set_flag("met_gran")


func _wellspring() -> void:
	if Game.heal_stage < 2 or Game.flags.get("wellspring_woken", false):
		return
	Game.set_flag("wellspring_woken")
	await world.healing.play_pending()
	await world.dialog.say(Db.lines("end_of_slice", Game.flags))
