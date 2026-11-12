class_name Team
extends RefCounted
## Your creatures (up to team_max), which one is out, the shared gauge, your materials and your items (used only
## outside battle). Pure state with signals: the field (TamerGame) and the HUD listen. Knocked-out members recover on their own over time (CreatureRecord.tick).

signal changed
signal leveled(rec: CreatureRecord)
signal evolved(rec: CreatureRecord)

var members: Array[CreatureRecord] = []
var sanctuary: Array[CreatureRecord] = []     ## synced creatures not in the team (move them at camp)
var active: int = -1
var materials: Dictionary = {}          ## material id -> count
var items: Dictionary = {}              ## item id -> count
var gauge: float = 0.0                  ## the shared gauge, in segments (0..segments): basics fill it, moves spend it


func _init() -> void:
	var defs: Dictionary = TamerData.rule("items")
	for id: String in defs:
		items[id] = int(defs[id]["count"])


func gauge_max() -> float:
	return float(TamerData.rule("combat.gauge.segments"))


func add_gauge(amount: float) -> void:
	gauge = minf(gauge_max(), gauge + amount)


## Spends whole segments; false (and nothing spent) when there are not enough.
func spend_gauge(segments: int) -> bool:
	if gauge + 0.001 < float(segments):
		return false
	gauge -= float(segments)
	return true


func full() -> bool:
	return members.size() >= int(TamerData.rule("team_max"))


## A newly synced creature: it joins the team while the team has fewer than sync_to_team, else the Sanctuary.
func sync(rec: CreatureRecord) -> bool:
	if members.size() < int(TamerData.rule("sync_to_team")):
		return add(rec)
	rec.wild = false
	sanctuary.append(rec)
	changed.emit()
	return false


## Sanctuary -> team (if the team has room).
func from_sanctuary(rec: CreatureRecord) -> bool:
	if full() or not sanctuary.has(rec):
		return false
	sanctuary.erase(rec)
	return add(rec)


## Team -> Sanctuary (never the one that is out, never the last one).
func to_sanctuary(rec: CreatureRecord) -> bool:
	var i: int = members.find(rec)
	if i < 0 or i == active or members.size() <= 1:
		return false
	members.remove_at(i)
	if active > i:
		active -= 1
	sanctuary.append(rec)
	changed.emit()
	return true


func add(rec: CreatureRecord) -> bool:
	if full():
		return false
	rec.wild = false
	rec.life = minf(rec.life, rec.max_life())
	_listen(rec)
	members.append(rec)
	if active < 0:
		active = members.size() - 1
	changed.emit()
	return true


## A whole new team (the Gate Hall's station); the first one is out.
func replace(recs: Array[CreatureRecord]) -> void:
	members.clear()
	active = -1
	for r: CreatureRecord in recs:
		add(r)


func _listen(rec: CreatureRecord) -> void:
	if not rec.growth.leveled.is_connected(_on_leveled):
		rec.growth.leveled.connect(_on_leveled)
		rec.growth.evolved.connect(_on_evolved)


func _on_leveled(rec: CreatureRecord) -> void:
	if members.has(rec):
		leveled.emit(rec)


func _on_evolved(rec: CreatureRecord) -> void:
	if members.has(rec):
		evolved.emit(rec)


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
