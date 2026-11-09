class_name BossArena
extends Area2D
## A boss room: when the player walks into this area, the boss wakes up and the arena's gates
## close behind them; when the boss falls, the gates open again. The area's own shape is
## the arena floor; the gates are ArenaGate nodes listed in `gates`.
## If the player falls mid-fight, the fight starts over (`start_over`, called by WorldReset):
## the gates open and the next walk in starts it again. Starting the fight also makes the
## arena's `checkpoint` the last one reached (silently), so a fall puts you back just outside.

## The group WorldReset calls `start_over` on.
const GROUP := "boss_arenas"

@export var boss: WardenCaptain
@export var gates: Array[ArenaGate] = []
## The checkpoint before the boss, where a fall in this fight puts the player.
@export var checkpoint: Checkpoint

var _has_started: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	if boss != null:
		boss.fight_started.connect(_close_gates)
		(boss.get_node("Health") as Health).died.connect(_open_gates)


func _on_body_entered(body: Node2D) -> void:
	if _has_started or boss == null or not body.is_in_group(PlayerFinder.GROUP):
		return
	boss.notice_player()
	_close_gates()


## Only with the player inside, so nobody is ever locked out of the fight.
func _close_gates() -> void:
	var player := PlayerFinder.find(self)
	if _has_started or player == null or not overlaps_body(player):
		return
	_has_started = true
	if checkpoint != null:
		checkpoint.reach(false)
	for gate in gates:
		gate.close()


## The player fell during the fight (or before it): open up and wait for them to walk in again.
## The boss itself goes back to its spawn with the other enemies (Enemy.return_to_spawn).
func start_over() -> void:
	if not _has_started or not is_instance_valid(boss) or boss.health.is_dead():
		return  # not started yet, or already won
	_has_started = false
	_open_gates()


func _open_gates() -> void:
	for gate in gates:
		gate.open()
