class_name NightRun
extends Node3D
## One defence night: the clock, the creatures coming in waves, the Gloom King at the end, experience and
## level-ups, the ingredient bag, and how it ends. Surviving until dawn or beating the Gloom King wins and keeps the
## whole bag; fainting is gentle: you wake at the café and keep part of it.

signal level_up_ready(offers: Array[Dictionary])
signal ended(won: bool, kept: Dictionary)

enum State { IDLE, RUNNING, ENDED }

const SECONDS_PER_MINUTE: float = 60.0

var state: State = State.IDLE
var clock: float = 0.0
var level: int = 1
var xp: float = 0.0
var bag: Dictionary = {}
var horde: Horde
var spawner: Spawner
var pickups: Pickups
var lamps: LampKeeper
var vitality: Vitality
var loadout: Loadout
var pantry := Pantry.new()
## The night's length and when the Gloom King comes (from data; tests may shorten them).
var length: float = 0.0
var boss_at: float = 0.0
var kills: int = 0
var _player: Player
var _boss_spawned: bool = false
var _summon_timer: float = 0.0
var _pending_levels: int = 0


func setup(player: Player, library: AssetLibrary, town_lamps: Array[LampLight]) -> void:
	name = "NightRun"
	_player = player
	lamps = LampKeeper.new()
	add_child(lamps)
	lamps.setup(town_lamps, player)
	vitality = Vitality.new()
	add_child(vitality)
	vitality.setup(player, lamps)
	horde = Horde.new()
	add_child(horde)
	horde.setup(library, player, lamps, vitality)
	spawner = Spawner.new()
	add_child(spawner)
	spawner.setup(horde, player)
	pickups = Pickups.new()
	add_child(pickups)
	pickups.setup(player)
	loadout = Loadout.new()
	add_child(loadout)
	loadout.setup(player, horde, vitality, pickups)
	horde.defeated.connect(_on_defeated)
	pickups.collected.connect(_on_collected)
	vitality.fainted.connect(finish.bind(false))
	pantry.load_stock()
	length = Tuning.number("defence", "run", "seconds")
	boss_at = Tuning.number("defence", "run", "boss_at")
	set_physics_process(false)


func start() -> void:
	_clean_up()
	vitality.reset(Tuning.number("defence", "player", "health"))
	loadout.reset()
	clock = 0.0
	level = 1
	xp = 0.0
	bag = {}
	kills = 0
	_boss_spawned = false
	_pending_levels = 0
	spawner.reset()
	state = State.RUNNING
	set_physics_process(true)


func xp_needed() -> float:
	var curve: Dictionary = Tuning.doc("defence")["xp"]
	return float(curve["first"]) * pow(float(curve["growth"]), level - 1) + float(curve["add"]) * (level - 1)


## Applies a chosen level-up offer and, if more levels are waiting, offers the next.
func choose(offer: Dictionary) -> void:
	loadout.apply(offer)
	_pending_levels -= 1
	if _pending_levels > 0:
		level_up_ready.emit(loadout.offers())


## The night ends: store the bag (all of it, or a share after fainting), tidy the town and go back to calm.
func finish(won: bool) -> void:
	if state != State.RUNNING:
		return
	state = State.ENDED
	set_physics_process(false)
	var kept: Dictionary = pantry.store(bag, 1.0 if won else Tuning.number("defence", "run", "fail_keep_share"))
	_clean_up()
	ended.emit(won, kept)
	state = State.IDLE


func _physics_process(delta: float) -> void:
	clock += delta
	horde.toughness = 1.0 + Tuning.number("defence", "growth", "health_per_minute") * clock / SECONDS_PER_MINUTE
	spawner.advance(clock, delta)
	if not _boss_spawned and clock >= boss_at:
		_boss_spawned = spawner.spawn_kind("gloom_king") != null
	_boss_powers(delta)
	if clock >= length:
		finish(true)


## The Gloom King calls ghosts to his side and snuffs the lamps he passes.
func _boss_powers(delta: float) -> void:
	var king: Creature = horde.boss()
	if king == null:
		return
	for lamp: LampLight in lamps.lamps:
		if lamp.lit and lamp.global_position.distance_to(king.global_position) < float(king.spec["snuff_radius"]):
			lamp.snuff()
	_summon_timer -= delta
	if _summon_timer <= 0.0:
		_summon_timer = float(king.spec["summon_every"])
		for index: int in int(king.spec["summon_count"]):
			var offset := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * king.radius * 2.0
			horde.spawn(king.spec["summon"], king.global_position + offset)


func _on_defeated(creature: Creature) -> void:
	kills += 1
	var bonus: String = Tuning.doc("defence")["creature"]["bonus_drop"]
	if creature.is_boss:
		_bag_add(creature.spec["drop"], int(creature.spec["drops"]))
		_bag_add(bonus, 1)
		finish(true)
		return
	pickups.drop(Pickups.XP, int(creature.spec["xp"]), creature.global_position)
	for index: int in int(creature.spec["drops"]):
		if randf() < float(creature.spec["drop_chance"]):
			pickups.drop(creature.spec["drop"], 1, creature.global_position)
	if randf() < Tuning.number("defence", "creature", "bonus_drop_chance"):
		pickups.drop(bonus, 1, creature.global_position)


func _bag_add(item: String, amount: int) -> void:
	bag[item] = int(bag.get(item, 0)) + amount


func _on_collected(item: String, amount: int) -> void:
	if item != Pickups.XP:
		_bag_add(item, amount)
		return
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		_pending_levels += 1
		if _pending_levels == 1:
			level_up_ready.emit(loadout.offers())


func _clean_up() -> void:
	horde.clear()
	pickups.clear()
	lamps.relight_all()
