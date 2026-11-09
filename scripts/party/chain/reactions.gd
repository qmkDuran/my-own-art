class_name Reactions
extends RefCounted
## Element reactions, Project B's own twist on tag-team chaining (see PROJECT_B.md,
## "Element reactions"): when a hit of one element lands on an enemy carrying a status from
## another, the status is cashed in for a bonus effect. One table, one sentence each.
## What each reaction does lives in ReactionEffects.

const STEAM_BURST := "steam_burst"
const WILDFIRE := "wildfire"
const DROWN := "drown"
const KINDLING := "kindling"
const TOXIC_BLAZE := "toxic_blaze"

## In priority order: the first row that matches is the one that fires.
## status: what the enemy carries; element: the hit's element; word: the burst on screen;
## short: the name on a READY pip; consumes: whether the status ends.
const TABLE: Array[Dictionary] = [
	{"id": STEAM_BURST, "status": SetUp.SOAKED, "element": "Fire", "word": "STEAM BURST!", "short": "STEAM", "consumes": true},
	{"id": DROWN, "status": SetUp.ROOTED, "element": "Tide", "word": "DROWN!", "short": "DROWN", "consumes": true},
	{"id": KINDLING, "status": SetUp.ROOTED, "element": "Fire", "word": "KINDLING!", "short": "KINDLE", "consumes": true},
	{"id": WILDFIRE, "status": SetUp.BURNING, "element": "Bloom", "word": "WILDFIRE!", "short": "WILDFIRE", "consumes": false},
	{"id": TOXIC_BLAZE, "status": SetUp.POISONED, "element": "Fire", "word": "TOXIC BLAZE!", "short": "BLAZE", "consumes": true},
]
## A reaction's word and impact frame show at most once per this many physics frames, so a
## Signal Skill that sets off five Steam Bursts at once still reads as one big beat.
const SHOW_GAP_FRAMES := 18

static var _last_shown_frame: Dictionary = {}


## The reaction a hit of `element` would set off on `target` right now ({} for none).
static func find_for(target: Node, element: String) -> Dictionary:
	if element.is_empty():
		return {}
	for reaction in TABLE:
		if reaction["element"] == element and SetUp.has(target, reaction["status"]):
			return reaction
	return {}


## Sets `reaction` off on the enemy with `target_health` (already hit by `attacker`).
static func trigger(reaction: Dictionary, attacker: Node2D, target_health: Health) -> void:
	var target := target_health.get_parent() as Node2D
	if target == null or not attacker.is_inside_tree():
		return
	if reaction["consumes"]:
		SetUp.consume(target, reaction["status"])
	var is_shown := _claim_show(reaction["id"])
	ReactionEffects.play(reaction["id"], attacker, target_health, is_shown)
	if is_shown:
		var color := ElementColors.for_element(reaction["element"])
		WordBurst.pop(target.get_parent(), target.global_position + Vector2(0, -22), reaction["word"], color)
	LinkMeter.add_from(attacker, LinkMeter.PER_REACTION)


static func _claim_show(reaction_id: String) -> bool:
	var now := Engine.get_physics_frames()
	var last: int = _last_shown_frame.get(reaction_id, -SHOW_GAP_FRAMES)
	if now - last < SHOW_GAP_FRAMES:
		return false
	_last_shown_frame[reaction_id] = now
	return true
