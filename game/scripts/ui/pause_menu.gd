class_name PauseMenu
extends Control
## The field menu (Esc/Tab/M): Team, Journal, Bag, Save, Close, with your coins and how healed the Vale is.

const ITEMS: PackedStringArray = ["Team", "Journal", "Bag", "Save", "Close"]
const W: int = 92


func run(world: Overworld) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view: Vector2 = get_viewport_rect().size
	var panel := UiKit.panel(Rect2(view.x - W - 4, 4, W, ITEMS.size() * MenuList.ROW_H + 34))
	add_child(panel)
	var list := MenuList.new()
	panel.add_child(list)
	list.setup(ITEMS, 1, W - 12)
	list.position = Vector2(5, 4)
	var coins := UiKit.label("%d coins" % Game.coins, "ember1", true)
	coins.position = Vector2(8, ITEMS.size() * MenuList.ROW_H + 8)
	panel.add_child(coins)
	var heal := UiKit.label("Vale healed %d/3" % Game.heal_stage, "leaf1", true)
	heal.position = Vector2(8, ITEMS.size() * MenuList.ROW_H + 18)
	panel.add_child(heal)
	while true:
		var i: int = await list.pick()
		if i < 0 or ITEMS[i] == "Close":
			return
		await _open(ITEMS[i], world)


func _open(item: String, world: Overworld) -> void:
	if item == "Save":
		SaveSystem.save()
		Audio.sfx("save")
		await world.dialog.say(PackedStringArray(["Your journey was saved."]))
		return
	var screen: ScreenPanel = {"Team": PartyPanel, "Journal": JournalPanel, "Bag": BagPanel}[item].new()
	add_child(screen)
	await screen.run()
	screen.queue_free()
