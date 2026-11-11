class_name BattleScene
extends CanvasLayer
## A battle, wild or against another tender: builds the stage (backdrop, creatures, cards, messages, menus, timing
## ring), runs rounds until someone wins, befriends or leaves, and returns the result.

signal finished(result: Dictionary)

const LAYER: int = 20

var kind: String = "wild"
var trainer_id: String = ""
var backdrop: String = "meadow"
var foe: Battler
var ally: Battler
var foe_queue: Array[Creature] = []
var fought: Array[Creature] = []
var stage_root: Control
var view: BattleView
var foe_card: CreatureCard
var ally_card: CreatureCard
var messages: BattleLog
var menus: BattleMenus
var ring: TimingRing
var rounds: BattleRound
var result: Dictionary = {}


func _init() -> void:
	layer = LAYER


func is_wild() -> bool:
	return kind == "wild"


func trainer_name() -> String:
	return String(Db.trainers[trainer_id]["name"]) if trainer_id != "" else ""


## Runs the whole battle; foes fight one after another (a wild battle has one).
func run(foes: Array[Creature]) -> Dictionary:
	foe_queue = foes.duplicate()
	_build()
	rounds = BattleRound.new(self)
	await _intro()
	while result.is_empty():
		var action: Dictionary = await menus.choose_action()
		await rounds.play(action)
	await _finish()
	finished.emit(result)
	return result


func _build() -> void:
	var back := ColorRect.new()
	back.color = UiKit.c("water4")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	stage_root = Control.new()
	stage_root.size = BattleLayout.STAGE
	add_child(stage_root)
	_place_stage()
	get_viewport().size_changed.connect(_place_stage)
	stage_root.add_child(_backdrop())
	view = BattleView.new()
	stage_root.add_child(view)
	foe_card = CreatureCard.new().setup(false)
	foe_card.position = BattleLayout.FOE_CARD
	ally_card = CreatureCard.new().setup(true)
	ally_card.position = BattleLayout.ALLY_CARD
	messages = BattleLog.new().setup(BattleLayout.LOG_RECT)
	for n: Control in [foe_card, ally_card, messages]:
		n.visible = false
		stage_root.add_child(n)
	messages.visible = true
	ring = TimingRing.new()
	stage_root.add_child(ring)
	menus = BattleMenus.new().setup(self)
	stage_root.add_child(menus)


func _place_stage() -> void:
	var view_size: Vector2 = stage_root.get_viewport_rect().size
	stage_root.position = ((view_size - BattleLayout.STAGE) / 2).floor()


func _backdrop() -> TextureRect:
	var t := TextureRect.new()
	var withered: bool = backdrop == "grove" and Game.heal_stage < 3
	t.texture = load("res://art/scenes/battle_%s%s.png" % [backdrop, "_withered" if withered else ""])
	return t


func _intro() -> void:
	foe = Battler.of(foe_queue.pop_front(), is_wild())
	Game.journal.see(foe.creature.species_id)
	if is_wild():
		foe.mood = TrustRules.roll_mood(foe.creature.species_id, Game.rng)
		await _show_foe()
		await messages.say("A wild %s peeks out at you!" % foe.creature.display_name())
	else:
		await messages.say("%s wants to battle!" % trainer_name())
		await send_foe()
	await send_ally(Game.lead())


func _show_foe() -> void:
	foe_card.show_battler(foe)
	foe_card.visible = true
	if foe.wild:
		foe_card.update_trust()
	await view.send_in(false, foe.creature)


func send_foe() -> void:
	Game.journal.see(foe.creature.species_id)
	await messages.say("%s sends out %s!" % [trainer_name(), foe.creature.display_name()])
	await _show_foe()


func send_ally(c: Creature) -> void:
	ally = Battler.of(c)
	if not fought.has(c):
		fought.append(c)
	await messages.say("Go, %s!" % c.display_name())
	ally_card.show_battler(ally)
	ally_card.visible = true
	await view.send_in(true, c)
	messages.show_now("What will %s do?" % c.display_name())


func next_foe() -> bool:
	if foe_queue.is_empty():
		return false
	foe = Battler.of(foe_queue.pop_front(), false)
	return true


func _finish() -> void:
	for c: Creature in fought:
		if not c.is_fainted():
			Bond.gain(c, "battle")
	await Game.wait(0.3)
