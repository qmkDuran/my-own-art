class_name SkillBar
extends Node
## The creature's skill slots (Q, W, E, R): reads the keys, checks Heat and cooldowns,
## then hands the move to the slot's SkillAction.
##
## Each SkillAction child says which slot it sits in. Slots without one are empty, and so
## are slots whose skill isn't learned in the Ember Tree yet (see EmberTree.is_skill_unlocked).
## The creature only asks "is a skill casting?" (to stop walking and jabbing) and
## listens to `skill_used` to face the aim and play the cast animation.

## Fired when a skill actually fires (Heat spent, cooldown started).
signal skill_used(slot_index: int)
## Fired when a key is pressed but the skill can't fire. `reason` is
## REFUSED_HEAT (not enough Heat) or REFUSED_COOLDOWN (still cooling down).
signal skill_refused(slot_index: int, reason: String)

const SLOT_COUNT := 4
const REFUSED_HEAT := "heat"
const REFUSED_COOLDOWN := "cooldown"

## Where the Heat to pay for skills comes from. Optional: without it every skill is free
## (creatures that don't run on Heat only wait out cooldowns).
@export var heat: Heat
@export var player_input: PlayerInput

## Slot index -> the action in that slot, or null for an empty slot.
var _actions: Array[SkillAction] = []
## Slot index -> seconds until that slot's skill can fire again.
var _cooldowns_left: Array[float] = []
## The action playing right now, or null.
var _casting: SkillAction = null

@onready var caster: PlayableCreature = get_parent()


func _ready() -> void:
	_actions.resize(SLOT_COUNT)
	_cooldowns_left.resize(SLOT_COUNT)
	_cooldowns_left.fill(0.0)
	for child in get_children():
		if child is SkillAction:
			_put_in_slot(child as SkillAction)


func _physics_process(delta: float) -> void:
	_tick_cooldowns(delta)
	if _casting != null and not _casting.is_casting:
		_casting = null
	for slot_index in SLOT_COUNT:
		if player_input.wants_skill(slot_index):
			try_use(slot_index)


# --- Slots (the HUD reads these) --------------------------------------------

## The action in a slot, or null when the slot is empty (or its skill isn't learned).
func action_in_slot(slot_index: int) -> SkillAction:
	return _action_in_slot(slot_index)


## The skill in a slot, or null when the slot is empty (or its skill isn't learned).
func skill_in_slot(slot_index: int) -> Skill:
	var action := _action_in_slot(slot_index)
	return action.skill if action != null else null


## Seconds until the slot's skill can fire again (0.0 = ready).
func cooldown_left(slot_index: int) -> float:
	if not _is_valid_slot(slot_index):
		return 0.0
	return _cooldowns_left[slot_index]


## How much of the cooldown is left: 1.0 = just used, 0.0 = ready.
func cooldown_fraction(slot_index: int) -> float:
	var skill := skill_in_slot(slot_index)
	if skill == null or skill.cooldown <= 0.0:
		return 0.0
	return clampf(cooldown_left(slot_index) / skill.cooldown, 0.0, 1.0)


## Takes `seconds` off every cooldown that is running (landed hits do this).
func shave_cooldowns(seconds: float) -> void:
	for slot_index in SLOT_COUNT:
		_cooldowns_left[slot_index] = maxf(0.0, _cooldowns_left[slot_index] - seconds)


# --- Firing -------------------------------------------------------------------

## Fires the skill in a slot if it can. Returns true if it fired.
## Refusals for Heat or cooldown are announced with `skill_refused`; an empty slot
## or a creature that can't act right now (mid-dodge, shoved) is simply ignored.
func try_use(slot_index: int) -> bool:
	var action := _action_in_slot(slot_index)
	if action == null or action.skill == null:
		return false
	if action == _casting and action.is_casting and action.ends_on_second_press():
		cancel_cast()
		return false
	if cooldown_left(slot_index) > 0.0:
		skill_refused.emit(slot_index, REFUSED_COOLDOWN)
		return false
	if not _can_pay(action.skill.heat_cost):
		skill_refused.emit(slot_index, REFUSED_HEAT)
		return false
	if is_casting() or not caster.can_start_skill():
		return false

	if heat != null:
		heat.try_spend(action.skill.heat_cost)
	_cooldowns_left[slot_index] = action.skill.cooldown
	_casting = action
	action.start(caster, caster.aim_direction())
	skill_used.emit(slot_index)
	return true


# --- Hooks for the creature ---------------------------------------------------

func is_casting() -> bool:
	return _casting != null and _casting.is_casting


## The animation the creature shows while casting ("" when not casting).
func cast_animation() -> String:
	return _casting.animation_name if is_casting() else ""


## How the creature moves while casting (zero = rooted).
func cast_velocity() -> Vector2:
	return _casting.caster_velocity() if is_casting() else Vector2.ZERO


## How far the creature's sprite rises while casting, in pixels.
func cast_lift() -> float:
	return _casting.caster_lift() if is_casting() else 0.0


## Whether the current cast makes the caster untouchable (false when nothing is casting).
func cast_makes_invulnerable() -> bool:
	return is_casting() and _casting.makes_caster_invulnerable()


## Whether a dodge may cut the current cast short (true when nothing is casting).
func allows_dodge() -> bool:
	return not is_casting() or _casting.can_be_cancelled()


## Stops the current cast right away. Safe to call when nothing is casting.
func cancel_cast() -> void:
	if _casting != null:
		_casting.cancel()
		_casting = null


# --- Inner workings -----------------------------------------------------------

func _put_in_slot(action: SkillAction) -> void:
	if not _is_valid_slot(action.slot_index):
		push_warning("SkillBar: %s has no slot %d." % [action.name, action.slot_index])
		return
	_actions[action.slot_index] = action


## Null for an empty slot and for a skill not learned in the Ember Tree.
func _action_in_slot(slot_index: int) -> SkillAction:
	if not _is_valid_slot(slot_index):
		return null
	var action := _actions[slot_index]
	if action == null or not EmberTree.is_skill_unlocked(action.name):
		return null
	return action


func _can_pay(heat_cost: int) -> bool:
	return heat == null or heat.has(heat_cost)


func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < SLOT_COUNT


func _tick_cooldowns(delta: float) -> void:
	for slot_index in SLOT_COUNT:
		_cooldowns_left[slot_index] = maxf(0.0, _cooldowns_left[slot_index] - delta)
