class_name SkillBarHud
extends Control
## Connects Emberoo's SkillBar to the HUD: fills the four SkillSlot children with their key
## letters (from the InputMap: skill_1..skill_4), skills, cooldowns and whether Emberoo's Heat
## covers each skill's cost, plays the trainer's shout and the slot flash when a skill is used,
## shows why a skill was refused, and the tooltip while the mouse hovers a slot.
##
## The SkillBar is read by name and duck typing (has_method / has_signal), so the HUD still
## works, with empty slots, while Emberoo has no SkillBar. Without a Heat node every skill
## counts as affordable.

## How often to look for Emberoo's SkillBar again while he has none, in seconds.
const SEARCH_INTERVAL := 1.0

@export var trainer: HudTrainer
@export var heat_flame: HeatFlame
@export var tooltip: SkillTooltip

var _skill_bar: Node
var _heat: Heat
var _slots: Array[SkillSlot] = []
var _search_left: float = 0.0
var _hovered_slot: SkillSlot


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in get_children():
		if child is SkillSlot:
			_slots.append(child)
			child.hovered.connect(_on_slot_hovered)
			child.unhovered.connect(_on_slot_unhovered)


func _process(delta: float) -> void:
	for index in _slots.size():
		_slots[index].key_label = InputKeyLabel.for_action(_slot_action(index))
	if not is_instance_valid(_skill_bar):
		_skill_bar = null
		_search_left -= delta
		if _search_left <= 0.0:
			_search_left = SEARCH_INTERVAL
			_connect_to_skill_bar()
		return
	for index in _slots.size():
		_update_slot(index)


func _connect_to_skill_bar() -> void:
	_skill_bar = PlayerFinder.find_component(self, "SkillBar")
	_heat = PlayerFinder.find_component(self, "Heat") as Heat
	if _skill_bar == null:
		return
	if _skill_bar.has_signal("skill_used"):
		_skill_bar.connect("skill_used", _on_skill_used)
	if _skill_bar.has_signal("skill_refused"):
		_skill_bar.connect("skill_refused", _on_skill_refused)


func _update_slot(index: int) -> void:
	var slot := _slots[index]
	slot.skill = _call_skill_bar("skill_in_slot", index, null)
	slot.set_cooldown(_call_skill_bar("cooldown_left", index, 0.0), _call_skill_bar("cooldown_fraction", index, 0.0))
	slot.has_enough_heat = _can_afford(slot.skill)


## Whether Emberoo has the Heat the skill costs (a skill without a `heat_cost` is free).
func _can_afford(skill: Resource) -> bool:
	if skill == null or not is_instance_valid(_heat):
		return true
	var cost: Variant = skill.get("heat_cost")
	return _heat.has(cost) if cost is int else true


## The input action that fires a slot: skill_1 for the first slot, and so on.
func _slot_action(index: int) -> StringName:
	return StringName("skill_%d" % (index + 1))


## Calls a SkillBar method that takes a slot index, or gives the fallback if it has no such method.
func _call_skill_bar(method: String, index: int, fallback: Variant) -> Variant:
	if _skill_bar == null or not _skill_bar.has_method(method):
		return fallback
	var result: Variant = _skill_bar.call(method, index)
	return fallback if result == null else result


func _on_skill_used(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	_slots[slot_index].flash_used()
	if trainer != null:
		trainer.shout()


func _on_skill_refused(slot_index: int, reason: String) -> void:
	match reason:
		"heat":
			if heat_flame != null:
				heat_flame.show_not_enough_heat()
		"cooldown":
			if slot_index >= 0 and slot_index < _slots.size():
				_slots[slot_index].flash_refused()


func _on_slot_hovered(slot: SkillSlot) -> void:
	_hovered_slot = slot
	if tooltip != null:
		tooltip.show_for(slot.skill, slot.get_global_rect())


func _on_slot_unhovered(slot: SkillSlot) -> void:
	if slot != _hovered_slot:
		return
	_hovered_slot = null
	if tooltip != null:
		tooltip.hide_tooltip()
