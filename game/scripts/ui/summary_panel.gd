class_name SummaryPanel
extends ScreenPanel
## One creature in full: its portrait, element, level and XP, Bond, stats and every move it knows.
## Left/right flips through the team; cancel closes.

const PORTRAIT: Vector2 = Vector2(0, 0)
const STATS_X: int = 152
const STAT_KEYS: Array[String] = ["atk", "def", "spd"]
const STAT_NAMES: Dictionary = {"atk": "Attack", "def": "Defense", "spd": "Speed"}

var _index: int = 0


func run_for(i: int) -> void:
	_index = i
	set_title("Summary")
	while true:
		_show(Game.party[_index])
		var step: int = await _wait_input()
		if step == 0:
			return
		_index = posmod(_index + step, Game.party.size())


func _wait_input() -> int:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("accept"):
			Audio.sfx("cancel")
			return 0
		if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_down"):
			return 1
		if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_up"):
			return -1
	return 0


func _show(c: Creature) -> void:
	clear_content()
	content.add_child(UiKit.panel(Rect2(PORTRAIT, Vector2(88, 88)), "cream", "ink"))
	var art := TextureRect.new()
	art.texture = UiKit.creature_tex(c.species_id, "front")
	art.position = PORTRAIT + Vector2(4, 4)
	content.add_child(art)
	add_label(c.display_name(), Vector2(94, -2))
	add_icon("res://art/ui/elem_%s.png" % c.element(), Vector2(95, 14))
	add_label(Db.element_name(c.element()), Vector2(108, 12), "ink2", true)
	add_label("Level %d" % c.level, Vector2(94, 24), "ink2", true)
	add_label("XP %d/%d" % [c.xp, Growth.xp_to_next(c.level)], Vector2(94, 34), "water2", true)
	_bond_block(c)
	_stats_block(c)
	_moves_block(c)


func _bond_block(c: Creature) -> void:
	add_label("Bond", Vector2(0, 92), "rose1", true)
	var m := Meter.new().setup(84, 5, "rose2")
	m.position = Vector2(0, 102)
	m.set_fraction(float(c.bond) / Bond.MAX_BOND)
	content.add_child(m)
	add_label(Bond.label(c.bond), Vector2(0, 108), "ink2", true)
	var evo: Dictionary = c.data().get("evolves", {})
	if not evo.is_empty():
		add_label("Grows at Bond %d, Lv %d" % [int(evo["bond"]), int(evo["level"])], Vector2(0, 118), "dusk", true)


func _stats_block(c: Creature) -> void:
	add_label("HP", Vector2(STATS_X, 0), "ink2", true)
	add_label("%d/%d" % [c.hp, c.max_hp()], Vector2(STATS_X + 60, -2))
	for k: int in STAT_KEYS.size():
		var key: String = STAT_KEYS[k]
		add_label(STAT_NAMES[key], Vector2(STATS_X, 12 + k * 11), "ink2", true)
		add_label(str(c.stat(key)), Vector2(STATS_X + 60, 10 + k * 11))


func _moves_block(c: Creature) -> void:
	add_label("Moves", Vector2(STATS_X, 48), "ink2", true)
	for i: int in c.moves.size():
		var m: Dictionary = Db.move(c.moves[i])
		var y: int = 58 + i * 12
		add_icon("res://art/ui/elem_%s.png" % m["element"], Vector2(STATS_X, y + 2))
		add_label(String(m["name"]), Vector2(STATS_X + 13, y - 1))
		var power: String = str(int(m["power"])) if m["kind"] == "attack" else "-"
		add_label(power, Vector2(STATS_X + 110, y + 1), "dusk", true)
