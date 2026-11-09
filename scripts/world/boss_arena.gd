class_name BossArena
extends Area2D
## A boss room: when the player walks into this area, the boss wakes up and the arena's gates
## close behind them; when the boss falls, the gates open again. The area's own shape is
## the arena floor; the gates are ArenaGate nodes listed in `gates`.

@export var boss: WardenCaptain
@export var gates: Array[ArenaGate] = []

var _has_started: bool = false


func _ready() -> void:
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
	for gate in gates:
		gate.close()


func _open_gates() -> void:
	for gate in gates:
		gate.open()
