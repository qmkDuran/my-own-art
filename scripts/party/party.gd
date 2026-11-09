class_name Party
extends Node2D
## Project B's team: up to three creatures (children of this node), one on the field at a
## time. Keys 1/2/3 swap the one in that slot in, at the same spot, with a SwapFlourish.
## Swaps share a short cooldown. Each member keeps its own health; a defeated member can't
## come back in. When the one on the field falls, the next standing member jumps in at
## once; when all have fallen, the level restarts. A swap also plays the outgoing member's
## Outro and the incoming one's Intro (SwapMove): its entrance, plus its Signal Skill when
## the card is lit (a condition it needs is on an enemy). The incoming creature can't be
## hurt until its entrance has landed (swap i-frames). With a full LinkMeter, a Signal Skill
## is a Link Finisher.
##
## Benching and fielding a member is PartyMemberSwitch's job. The camera follows whoever is
## on the field. The HUD's TeamPanel reads the members, the active slot and the cooldown.

const GROUP := "party"
const MAX_MEMBERS := 3
## A member's swap-chain moves (SwapMove) go by these child names.
const OUTRO_NODE := "Outro"
const INTRO_NODE := "Intro"

## Seconds after a swap before the next one.
@export var swap_cooldown: float = 1.5
## Seconds the incoming creature can't be hurt (about 8 frames), so a swap can dodge a hit.
@export var entrance_shield_seconds: float = 0.14
## Follows the creature on the field.
@export var camera: Camera2D
## The ring used by the swap-in burst.
@export var ring_scene: PackedScene
## The team's Link meter (optional).
@export var link_meter: LinkMeter

var members: Array[PlayableCreature] = []
var active_slot: int = 0

var _cooldown_left: float = 0.0


func _ready() -> void:
	add_to_group(GROUP)
	for child in get_children():
		if child is PlayableCreature and members.size() < MAX_MEMBERS:
			_join(child as PlayableCreature)
	for slot_index in members.size():
		if slot_index == active_slot:
			PartyMemberSwitch.bring_in(members[slot_index], members[slot_index].global_position)
		else:
			PartyMemberSwitch.bench(members[slot_index])


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	var input := active_member().player_input
	for slot_index in members.size():
		if input.wants_team_swap(slot_index):
			try_swap_to(slot_index)
	if camera != null:
		camera.global_position = active_member().global_position


func active_member() -> PlayableCreature:
	return members[active_slot]


## The swap cooldown still to run, as a share of the full cooldown (1 = just swapped).
func swap_cooldown_fraction() -> float:
	return clampf(_cooldown_left / swap_cooldown, 0.0, 1.0) if swap_cooldown > 0.0 else 0.0


## The status on a nearby enemy that would fire the Signal Skill of the member in
## `slot_index` if swapped in now ("" when not armed); its card shows that status's icon.
func armed_status(slot_index: int) -> String:
	if slot_index == active_slot or members[slot_index].health_component().is_dead():
		return ""
	var intro := members[slot_index].get_node_or_null(INTRO_NODE) as SwapMove
	return intro.armed_status_at(active_member().global_position) if intro != null else ""


func can_swap_to(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < members.size() and slot_index != active_slot \
			and _cooldown_left <= 0.0 and not members[slot_index].health_component().is_dead()


## Swaps the member in `slot_index` onto the field. True if it did.
func try_swap_to(slot_index: int) -> bool:
	if not can_swap_to(slot_index):
		return false
	_swap_to(slot_index)
	return true


func _join(member: PlayableCreature) -> void:
	members.append(member)
	member.restarts_level_on_death = false
	member.health_component().died.connect(_on_member_defeated.bind(member))


func _swap_to(slot_index: int) -> void:
	var outgoing := active_member()
	var incoming := members[slot_index]
	var spot := outgoing.global_position
	var intro := incoming.get_node_or_null(INTRO_NODE) as SwapMove
	var is_signal := intro != null and intro.is_armed_at(spot)
	_send_off(outgoing, incoming)
	active_slot = slot_index
	_bring_on(incoming, spot, intro)
	if is_signal and intro is SignalSkill:
		_make_link_finisher_if_meter_full(intro as SignalSkill)
	_play_swap_move(incoming, INTRO_NODE, outgoing)
	_cooldown_left = swap_cooldown
	if camera != null:
		camera.offset = Vector2.ZERO


## The outgoing member strikes its exit pose, plays its Outro and leaves the field.
func _send_off(outgoing: PlayableCreature, incoming: PlayableCreature) -> void:
	outgoing.show_exit_pose()
	SwapFlourish.play_exit(outgoing)
	_play_swap_move(outgoing, OUTRO_NODE, incoming)
	PartyMemberSwitch.bench(outgoing)


## The incoming member lands at `spot`, untouchable until its entrance (`intro`'s) is over.
func _bring_on(incoming: PlayableCreature, spot: Vector2, intro: SwapMove) -> void:
	PartyMemberSwitch.bring_in(incoming, spot)
	incoming.entrance_shield_left = entrance_shield_seconds + (intro.entrance_seconds() if intro != null else 0.0)
	incoming.play_entrance_pose()
	SwapFlourish.play_entrance(incoming, ring_scene)


## A full Link meter turns the Signal Skill about to fire into a Link Finisher. The meter
## is only spent if the finisher hits something (see SignalSkill).
func _make_link_finisher_if_meter_full(signal_skill: SignalSkill) -> void:
	if link_meter != null and link_meter.is_full():
		signal_skill.is_link_finisher = true


## Plays the member's Outro or Intro, if it has one (see SwapMove).
func _play_swap_move(member: PlayableCreature, move_name: String, partner: PlayableCreature) -> void:
	var move := member.get_node_or_null(move_name) as SwapMove
	if move != null and not member.health_component().is_dead():
		move.play(member, partner)


## The member on the field fell: the next one still standing jumps in (no cooldown wait),
## once the frame is over.
func _on_member_defeated(member: PlayableCreature) -> void:
	if member == active_member():
		_replace_fallen_member.call_deferred()


## Brings in the next member still standing, or restarts the level when none is. Looked up
## only now, so a swap the player made in the same frame isn't swapped over again.
func _replace_fallen_member() -> void:
	if not active_member().health_component().is_dead():
		return
	for step in range(1, members.size()):
		var slot_index := (active_slot + step) % members.size()
		if not members[slot_index].health_component().is_dead():
			_swap_to(slot_index)
			return
	get_tree().reload_current_scene()
