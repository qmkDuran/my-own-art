class_name Team
extends RefCounted
## Your creatures (up to team_max), which one is out, your materials and your items. Pure state with signals: the
## field (TamerGame) and the HUD listen. Knocked-out members recover on their own over time (CreatureRecord.tick).

signal changed
signal joined(rec: CreatureRecord)
signal bond_unlocked(rec: CreatureRecord)

var members: Array[CreatureRecord] = []
var active: int = -1
var materials: Dictionary = {}          ## material id -> count
var items: Dictionary = {}              ## item id -> count


func _init() -> void:
	var defs: Dictionary = TamerData.rule("items")
	for id: String in defs:
		items[id] = int(defs[id]["count"])


func full() -> bool:
	return members.size() >= int(TamerData.rule("team_max"))


func add(rec: CreatureRecord) -> bool:
	if full():
		return false
	rec.wild = false
	rec.life = minf(rec.life, rec.max_life())
	rec.bond_unlocked.connect(func(r: CreatureRecord) -> void: bond_unlocked.emit(r))
	members.append(rec)
	if active < 0:
		active = members.size() - 1
	joined.emit(rec)
	changed.emit()
	return true


func current() -> CreatureRecord:
	return members[active] if active >= 0 and active < members.size() else null


func can_swap_to(i: int) -> bool:
	return i >= 0 and i < members.size() and i != active and not members[i].knocked_out()


func set_active(i: int) -> void:
	active = i
	changed.emit()


## The first member that can fight, other than the current one (-1: none).
func next_awake() -> int:
	for i: int in members.size():
		if i != active and not members[i].knocked_out():
			return i
	return -1


func all_out() -> bool:
	return members.all(func(r: CreatureRecord) -> bool: return r.knocked_out())


func tick(delta: float) -> void:
	for r: CreatureRecord in members:
		r.tick(delta)


func add_material(id: String, n: int) -> void:
	materials[id] = int(materials.get(id, 0)) + n
	changed.emit()


func count(id: String) -> int:
	return int(materials.get(id, 0))


## Raise `stat` of `rec` one level, paying its material. Returns whether it worked.
func upgrade(rec: CreatureRecord, stat: String) -> bool:
	var cost: int = rec.upgrade_cost(stat)
	var mat: String = String(TamerData.rule("upgrades." + stat + ".material"))
	if cost < 0 or count(mat) < cost:
		return false
	materials[mat] = count(mat) - cost
	rec.upgrades[stat] = int(rec.upgrades[stat]) + 1
	changed.emit()
	return true


func use_item(id: String) -> bool:
	if int(items.get(id, 0)) <= 0:
		return false
	items[id] = int(items[id]) - 1
	changed.emit()
	return true


## Camp: everyone whole and awake.
func rest() -> void:
	for r: CreatureRecord in members:
		r.revive(1.0)
		r.life = r.max_life()
	changed.emit()
