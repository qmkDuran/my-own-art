class_name Hit
extends RefCounted
## One blow from the player: how much, of which kind (primary, heavy, bomb, super: shields take each kind at their
## own rate), where it landed, which way it pushes, and whether it was a critical hit.

const TINY: float = 0.0001
## The delay between the flame bursts of a line attack landing.
const LINE_DELAY: float = 0.03
## How slow time runs during a hit-stop.
const STOP_SCALE: float = 0.05

var amount: float = 0.0
var kind: String = ""

var point: Vector3 = Vector3.ZERO
var push: Vector3 = Vector3.ZERO
var critical: bool = false
## Set when the hit landed on a shield rather than the body.
var on_shield: bool = false


func _init(hit_amount: float, hit_kind: String, at: Vector3, push_by: Vector3 = Vector3.ZERO) -> void:
	amount = hit_amount
	kind = hit_kind
	point = at
	push = push_by
