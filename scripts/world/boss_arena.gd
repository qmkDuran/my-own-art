class_name BossArena
extends Area2D
## A boss room: when the player walks into this area, the boss wakes up and the arena's gates
## close behind them; when the boss falls, the gates open again. The area's own shape is
## the arena floor; the gates are ArenaGate nodes listed in `gates`.
## If the player falls mid-fight, the fight starts over (`start_over`, called by WorldReset):
## the gates open and the next walk in starts it again. Starting the fight also makes the
## arena's `checkpoint` the last one reached (silently), so a fall puts you back just outside.
##
## The boss can be any enemy. The Warden Captain shows his own boss bar; for any other (e.g. an
## elite standing in as a zone's boss) `boss_bar_name` makes the arena show and hide the bar.
## Beaten once, the boss stays beaten: his `defeated_flag` (StoryFlags) is set, and a later
## visit finds the arena empty with its gates open (and the road on, e.g. a ZoneExit, open too).

## The group WorldReset calls `start_over` on.
const GROUP := "boss_arenas"

@export var boss: Enemy
@export var gates: Array[ArenaGate] = []
## The checkpoint before the boss, where a fall in this fight puts the player.
@export var checkpoint: Checkpoint
## The name on the boss bar, for a boss that doesn't show one itself ("" = no bar from here).
@export var boss_bar_name: String = ""
## Set when the boss falls; while it's set the boss is gone ("" = he comes back every visit).
@export var defeated_flag: String = ""

var _has_started: bool = false


func _ready() -> void:
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	if boss != null and defeated_flag != "" and StoryFlags.has(defeated_flag):
		boss.queue_free()
		boss = null
	if boss != null:
		if boss.has_signal("fight_started"):
			boss.connect("fight_started", _close_gates)
		boss.health.died.connect(_on_boss_died)
		Health.of(boss).died.connect(StoryFlags.set_flag.bind(defeated_flag))


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
	if boss_bar_name != "":
		BossHealthBar.show_boss(self, boss_bar_name, boss.health)
	for gate in gates:
		gate.close()


## The player fell during the fight (or before it): open up and wait for them to walk in again.
## The boss itself goes back to its spawn with the other enemies (Enemy.return_to_spawn).
func start_over() -> void:
	if not _has_started or not is_instance_valid(boss) or boss.health.is_dead():
		return  # not started yet, or already won
	_has_started = false
	if boss_bar_name != "":
		BossHealthBar.hide_boss(self)
	_open_gates()


func _on_boss_died() -> void:
	if boss_bar_name != "":
		BossHealthBar.announce_defeat(self, boss_bar_name)
	_open_gates()


func _open_gates() -> void:
	for gate in gates:
		gate.open()
