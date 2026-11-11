class_name BattleMenus
extends Control
## Choosing what to do in battle: the command panel (Strike, Befriend, Bag, Team, Run) and its sub-menus
## (moves with an info panel, gentle actions, treats, heals, team). Returns one action dictionary per turn.
## Tests queue actions in `queued` to skip the menus.

const COMMANDS: PackedStringArray = ["Strike", "Befriend", "Bag", "Team", "Run"]
const GENTLE: PackedStringArray = ["Calm", "Play", "Treat"]
const GENTLE_IDS: PackedStringArray = ["calm", "play", "treat"]

var queued: Array[Dictionary] = []
var battle: BattleScene
var _cmd_panel: Panel
var _sub_panel: Panel
var _info: MoveInfo


func setup(b: BattleScene) -> BattleMenus:
	battle = b
	size = BattleLayout.STAGE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func choose_action() -> Dictionary:
	if not queued.is_empty():
		await get_tree().process_frame
		return queued.pop_front()
	while true:
		var cmd: int = await _pick_in(BattleLayout.CMD_RECT, COMMANDS, 2, BattleLayout.CMD_COL_W, _cmd_enabled(), false)
		var action: Dictionary = await _sub_action(cmd)
		if not action.is_empty():
			return action
	return {}


func _cmd_enabled() -> Array[bool]:
	var wild: bool = battle.is_wild()
	return [true, wild, true, Game.able_count() > 1, wild]


func _sub_action(cmd: int) -> Dictionary:
	match cmd:
		0:
			return await _pick_move()
		1:
			return await _pick_gentle()
		2:
			return await _pick_item("heal")
		3:
			return await pick_switch(true)
		4:
			return {"type": "run"}
	return {}


func _pick_move() -> Dictionary:
	var moves: PackedStringArray = battle.ally.creature.moves
	var names: PackedStringArray = []
	for m: String in moves:
		names.append(String(Db.move(m)["name"]))
	_info = MoveInfo.new()
	battle.stage_root.add_child(_info)
	_info.setup(BattleLayout.INFO_RECT, battle.foe.creature)
	var i: int = await _pick_in(BattleLayout.MOVES_RECT, names, 2, BattleLayout.MOVE_COL_W, [], true,
		func(idx: int) -> void: _info.show_move(moves[idx]))
	_info.queue_free()
	return {} if i < 0 else {"type": "move", "move": moves[i]}


func _pick_gentle() -> Dictionary:
	var i: int = await _pick_in(BattleLayout.CMD_RECT, GENTLE, 1, BattleLayout.CMD_COL_W * 2, [], true)
	if i < 0:
		return {}
	if GENTLE_IDS[i] != "treat":
		return {"type": "gentle", "how": GENTLE_IDS[i]}
	var treat: Dictionary = await _pick_item("treat")
	return {} if treat.is_empty() else {"type": "gentle", "how": "treat", "item": treat["item"]}


func _pick_item(kind: String) -> Dictionary:
	var ids: PackedStringArray = Game.bag.ids(kind)
	if ids.is_empty():
		await battle.messages.say("You have no %s." % ("treats" if kind == "treat" else "healing items"))
		return {}
	var names: PackedStringArray = []
	for id: String in ids:
		names.append("%s x%d" % [Db.item(id)["name"], Game.bag.count(id)])
	var i: int = await _pick_in(BattleLayout.MOVES_RECT, names, 2, BattleLayout.MOVE_COL_W, [], true)
	return {} if i < 0 else {"type": "item", "item": ids[i]}


## Picks a creature to send in; `optional` allows backing out (a forced swap after fainting does not).
func pick_switch(optional: bool) -> Dictionary:
	var names: PackedStringArray = []
	var ok: Array[bool] = []
	for c: Creature in Game.party:
		names.append("%s %d/%d" % [c.display_name(), c.hp, c.max_hp()])
		ok.append(not c.is_fainted() and c != battle.ally.creature)
	var i: int = await _pick_in(BattleLayout.MOVES_RECT, names, 2, BattleLayout.MOVE_COL_W + 4, ok, optional)
	return {} if i < 0 else {"type": "switch", "index": i}


func _pick_in(rect: Rect2, items: PackedStringArray, cols: int, col_w: int, ok: Array[bool], cancellable: bool,
		on_move: Callable = Callable()) -> int:
	var panel := UiKit.panel(rect)
	battle.stage_root.add_child(panel)
	var list := MenuList.new()
	panel.add_child(list)
	list.setup(items, cols, col_w)
	list.position = Vector2(4, 3)
	list.cancellable = cancellable
	for k: int in ok.size():
		list.set_enabled(k, ok[k])
	if on_move.is_valid():
		list.index_changed.connect(on_move)
		on_move.call(0)
	var covers_log: bool = rect.intersects(BattleLayout.LOG_RECT)
	battle.messages.visible = not covers_log
	var i: int = await list.pick()
	panel.queue_free()
	battle.messages.visible = true
	return i


## After a faint: the next creature (tests and fast runs take the first one able to battle).
func pick_forced_switch() -> Dictionary:
	if not queued.is_empty() and queued[0]["type"] == "switch":
		return queued.pop_front()
	if Game.fast:
		for i: int in Game.party.size():
			if not Game.party[i].is_fainted():
				return {"type": "switch", "index": i}
	await battle.messages.say("Who will you send in?")
	return await pick_switch(false)
