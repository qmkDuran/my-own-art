class_name MoveBook
extends RefCounted
## Runs a creature's move by its kind (data/tamer/moves.json "kind"). Open for new kinds: add a MoveKind subclass to
## KINDS; nothing else changes.

static var _kinds: Dictionary = {}


static func kinds() -> Dictionary:
	if _kinds.is_empty():
		_kinds = {"strike": StrikeMove.new(), "bolt": BoltMove.new(), "lunge": LungeMove.new(), "burst": BurstMove.new(),
			"guard": GuardMove.new(), "status": StatusMove.new(), "wall": WallMove.new()}
	return _kinds


## `strength` (0..1) is how long a status move was channelled; other moves ignore it.
static func cast(user: Creature, id: String, at: Vector2, strength: float = 1.0) -> void:
	var m: Dictionary = TamerData.move(id)
	(kinds()[String(m["kind"])] as MoveKind).cast(user, m, at, strength)
	if bool(m.get("signature", false)):
		TamerFx.word(user.global_position, String(m["name"]) + "!", Pal.c("rose"), UiDraw.TITLE)
		Fx.screen_flash(TamerData.color(CreatureCombat.move_element(user, m)), 0.25, 0.35)
