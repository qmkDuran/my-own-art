class_name EmberTreeEffects
extends Node
## Applies the learned Ember Tree stat nodes to the player creature.
##
## Lives in the level (not on the creature), so the creature script stays untouched.
## EmberTreeStatSheet shows the same numbers on the tree screen; keep the two in step.
## It remembers how much it has already added, so learning, unlearning and the level
## restarting all end up with exactly the learned total, never counted twice.

## Stat names used by EmberTreeData's "stats" entries.
const MAX_HEALTH := "max_health"
const JAB_DAMAGE := "jab_damage"
const JAB_RECOVERY_CUT := "jab_recovery_cut"
const MOVE_SPEED := "move_speed"
const DODGE_COOLDOWN_CUT := "dodge_cooldown_cut"
const MAX_HEAT := "max_heat"

var _player: Node
## Stat name -> amount this component has added to the player so far.
var _applied: Dictionary[String, float] = {}


func _ready() -> void:
	# Wait one frame so the player has been added to the level (same as the HUD).
	await get_tree().process_frame
	_player = PlayerFinder.find(self)
	if _player == null:
		return
	EmberTree.changed.connect(_apply_learned_nodes)
	_apply_learned_nodes()


func _apply_learned_nodes() -> void:
	var wanted := _learned_totals()
	for stat in _all_stat_names(wanted):
		var change: float = wanted.get(stat, 0.0) - _applied.get(stat, 0.0)
		if is_zero_approx(change):
			continue
		_change_stat(stat, change)
		_applied[stat] = wanted.get(stat, 0.0)


func _learned_totals() -> Dictionary[String, float]:
	var totals: Dictionary[String, float] = {}
	for id in EmberTree.learned_ids():
		var stat_changes: Dictionary = EmberTreeData.find(id).stat_changes
		for stat: String in stat_changes:
			totals[stat] = totals.get(stat, 0.0) + float(stat_changes[stat])
	return totals


## Stats that are learned now or were applied before (so unlearned ones get taken back).
func _all_stat_names(wanted: Dictionary[String, float]) -> Array[String]:
	var names: Array[String] = wanted.keys()
	for stat in _applied:
		if not names.has(stat):
			names.append(stat)
	return names


func _change_stat(stat: String, change: float) -> void:
	match stat:
		MAX_HEALTH:
			Health.of(_player).change_max_health(roundi(change))
		JAB_DAMAGE:
			(_player.get_node(MeleeAttack.NODE_NAME) as MeleeAttack).damage += roundi(change)
		JAB_RECOVERY_CUT:
			(_player.get_node(MeleeAttack.NODE_NAME) as MeleeAttack).recovery_cut += change
		MOVE_SPEED:
			(_player.get_node(Movement.NODE_NAME) as Movement).top_speed += change
		DODGE_COOLDOWN_CUT:
			(_player.get_node(Dodge.NODE_NAME) as Dodge).cooldown -= change
		MAX_HEAT:
			(_player.get_node(Heat.NODE_NAME) as Heat).max_heat += roundi(change)
		_:
			push_warning("Ember Tree: no effect is wired up for stat '%s'." % stat)
