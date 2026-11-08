class_name EmberTreeData
extends RefCounted
## What is in Emberoo's Ember Tree: its branches and nodes (see DESIGN.md, "Build system").
##
## Content only. Add, move or reword nodes here without touching the rules (EmberTree)
## or the screen (EmberTreeScreen). Each branch is a direction out from Emberoo; nodes
## further out need a node closer in. Inner ring = Stage 1, middle = Stage 2, outer = Stage 3.

const Kind := EmberTreeNode.Kind

## Each branch: its name, what it is about in a few words (`theme`), how it plays
## (`playstyle`, shown when the player hovers its name) and its direction from the
## centre, in degrees (0 = right, -90 = up).
const BRANCHES := {
	"inferno": {"title": "Inferno", "theme": "Burn and fire damage", "angle": -90.0,
		"playstyle": "Set enemies on fire and let it spread. Burns keep hurting after you move on."},
	"flurry": {"title": "Flurry", "theme": "Speed and combos", "angle": 30.0,
		"playstyle": "Stay on the move: faster jabs, faster feet and a dodge that is ready sooner."},
	"bruiser": {"title": "Bruiser", "theme": "Toughness", "angle": 150.0,
		"playstyle": "Stand your ground: more health, and a brace that soaks hits and punches back."},
}

## Siblings on the same tier fan out this many degrees either side of their branch.
const SPREAD_NEAR := 20.0
const SPREAD_FAR := 15.0

## Each row's "text" is one short flavour clause; the exact effect is in "facts", or is
## worked out live from "stats" (see EmberTreeStatSheet). Facts hold real numbers and stay
## true for any enemy. Numbers on nodes that aren't built yet are the plan.
const NODE_ROWS := [
	# --- Inferno: set things on fire and let it spread -------------------------
	{"id": "searing_jab", "branch": "inferno", "stage": 1, "tier": 0, "kind": Kind.SKILL,
		"skill_action": "SearingJab",
		"title": "Searing Jab", "text": "Your fists catch fire.",
		"facts": "Every jab and Spinning Hook that lands sets the enemy burning: {burn_damage} damage per second for {burn_duration}s.\nNo Heat cost"},
	{"id": "hot_knuckles", "branch": "inferno", "stage": 1, "tier": 1, "angle": -SPREAD_NEAR, "kind": Kind.STAT,
		"requires": ["searing_jab"], "stats": {EmberTreeEffects.JAB_DAMAGE: 1},
		"title": "Hot Knuckles", "text": "Heavier fists."},
	{"id": "flame_uppercut", "branch": "inferno", "stage": 1, "tier": 1, "angle": SPREAD_NEAR, "kind": Kind.SKILL,
		"requires": ["searing_jab"], "skill_action": "FlameUppercut",
		"title": "Flame Uppercut", "text": "A rising punch that bursts into flame.",
		"facts": "{damage} damage to every enemy in a {arc_degrees}° arc in front, {reach}px reach, and knocks them back.\nCosts {heat_cost} Heat  ∙  {cooldown}s cooldown"},
	{"id": "kindling", "branch": "inferno", "stage": 1, "tier": 2, "angle": -SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["hot_knuckles"], "skill_action": "SearingJab",
		"title": "Kindling", "text": "Slow-burning coals.",
		"facts": "Burns last twice as long: {burn_duration}s → {kindled_duration}s."},
	{"id": "wildfire", "branch": "inferno", "stage": 1, "tier": 2, "angle": SPREAD_FAR, "kind": Kind.UPGRADE,
		"requires": ["flame_uppercut"], "skill_action": "Wildfire",
		"title": "Wildfire", "text": "The fire looks for more fuel.",
		"facts": "Flame Uppercut upgrade. An enemy that dies while burning passes its burn, at full length, to the nearest enemy within {radius}px."},

	# --- Flurry: be fast, chain punches ---------------------------------------
	{"id": "spinning_hook", "branch": "flurry", "stage": 1, "tier": 0, "kind": Kind.SKILL,
		"skill_action": "SpinningHook",
		"title": "Spinning Hook", "text": "The combo ends in a spin.",
		"facts": "Every 3rd punch in a chain is a spinning hook: {damage} damage to every enemy within {radius}px, and knocks them back.\nNo Heat cost"},
	{"id": "quick_hands", "branch": "flurry", "stage": 1, "tier": 1, "angle": -SPREAD_NEAR, "kind": Kind.STAT,
		"requires": ["spinning_hook"], "stats": {EmberTreeEffects.JAB_RECOVERY_CUT: 0.08},
		"title": "Quick Hands", "text": "Faster recovery after each punch."},
	{"id": "ember_hop", "branch": "flurry", "stage": 1, "tier": 1, "angle": SPREAD_NEAR, "kind": Kind.SKILL,
		"requires": ["spinning_hook"], "skill_action": "EmberHop",
		"title": "Ember Hop", "text": "Your dodge leaves fire behind.",
		"facts": "Each dodge leaves a fire trail for {trail_duration}s. Enemies that touch it burn: {burn_damage} damage per second for {burn_duration}s.\nNo Heat cost"},
	{"id": "light_feet", "branch": "flurry", "stage": 1, "tier": 2, "angle": -SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["quick_hands"], "stats": {EmberTreeEffects.MOVE_SPEED: 12.0},
		"title": "Light Feet", "text": "Lighter on your feet."},
	{"id": "spring_legs", "branch": "flurry", "stage": 1, "tier": 2, "angle": SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["ember_hop"], "stats": {EmberTreeEffects.DODGE_COOLDOWN_CUT: 0.25},
		"title": "Spring Legs", "text": "Land ready to leap again."},

	# --- Bruiser: stand your ground and take it --------------------------------
	{"id": "ash_guard", "branch": "bruiser", "stage": 1, "tier": 0, "kind": Kind.SKILL,
		"skill_action": "AshGuard",
		"title": "Ash Guard", "text": "Harden into ash.",
		"facts": "Raise your guard for {guard_duration}s: you take {damage_taken_percent}% damage and can't be shoved, but can't move. Press W again or attack to drop it.\nCosts {heat_cost} Heat  ∙  {cooldown}s cooldown"},
	{"id": "thick_hide", "branch": "bruiser", "stage": 1, "tier": 1, "angle": -SPREAD_NEAR, "kind": Kind.STAT,
		"requires": ["ash_guard"], "stats": {EmberTreeEffects.MAX_HEALTH: 2},
		"title": "Thick Hide", "text": "Tougher skin."},
	{"id": "counter_punch", "branch": "bruiser", "stage": 1, "tier": 1, "angle": SPREAD_NEAR, "kind": Kind.UPGRADE,
		"requires": ["ash_guard"], "skill_action": "CounterPunch",
		"title": "Counter Punch", "text": "Hit back without thinking.",
		"facts": "Ash Guard upgrade. Take a hit while guarding and your next punch within {window}s is a sure critical hit that throws enemies back hard."},
	{"id": "iron_gut", "branch": "bruiser", "stage": 1, "tier": 2, "angle": -SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["thick_hide"], "stats": {EmberTreeEffects.MAX_HEALTH: 3},
		"title": "Iron Gut", "text": "Built to stay in the fight."},
	{"id": "unshakable", "branch": "bruiser", "stage": 1, "tier": 2, "angle": SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["counter_punch"], "skill_action": "Unshakable",
		"title": "Unshakable", "text": "Feet like roots.",
		"facts": "Enemy shoves and rams (Warden rods, Gruntite charges, gusts) push you only {push_percent}% as far."},

	# --- Stage 2: opens at the first evolution ----------------------------------
	{"id": "meteor_fist", "branch": "inferno", "stage": 2, "tier": 3, "angle": -SPREAD_FAR, "kind": Kind.SKILL,
		"requires": ["kindling"],
		"title": "Meteor Fist", "text": "Fall like a meteor.",
		"facts": "Leap and land fist-first: 4 damage to every enemy within 32px, then the ground burns for 3s."},
	{"id": "heat_sink", "branch": "inferno", "stage": 2, "tier": 3, "angle": SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["wildfire"], "stats": {EmberTreeEffects.MAX_HEAT: 2},
		"title": "Heat Sink", "text": "A deeper fire inside."},
	{"id": "blur_step", "branch": "flurry", "stage": 2, "tier": 3, "angle": -SPREAD_FAR, "kind": Kind.SKILL,
		"requires": ["light_feet"],
		"title": "Blur Step", "text": "Leave yourself behind.",
		"facts": "Dodging through an enemy leaves an afterimage that jabs it once."},
	{"id": "second_wind", "branch": "flurry", "stage": 2, "tier": 3, "angle": SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["spring_legs"], "stats": {EmberTreeEffects.MOVE_SPEED: 12.0},
		"title": "Second Wind", "text": "Even lighter on your feet."},
	{"id": "molten_armour", "branch": "bruiser", "stage": 2, "tier": 3, "angle": -SPREAD_FAR, "kind": Kind.SKILL,
		"requires": ["iron_gut"],
		"title": "Molten Armour", "text": "Skin like hot rock.",
		"facts": "Enemies that hit you in melee take 1 damage and start burning."},
	{"id": "big_heart", "branch": "bruiser", "stage": 2, "tier": 3, "angle": SPREAD_FAR, "kind": Kind.STAT,
		"requires": ["unshakable"], "stats": {EmberTreeEffects.MAX_HEALTH: 3},
		"title": "Big Heart", "text": "Bigger body, bigger heart."},

	# --- Stage 3: Ultimates, at the final evolution -----------------------------
	{"id": "blazing_sun", "branch": "inferno", "stage": 3, "tier": 4, "kind": Kind.ULTIMATE,
		"requires": ["meteor_fist", "heat_sink"],
		"title": "Blazing Sun", "text": "Become a living sun.",
		"facts": "For 5s, every enemy within 48px of you burns."},
	{"id": "inferno_rush", "branch": "flurry", "stage": 3, "tier": 4, "kind": Kind.ULTIMATE,
		"requires": ["blur_step", "second_wind"],
		"title": "Inferno Rush", "text": "A storm of blazing punches.",
		"facts": "8 jabs in 1.5s, then a blast: 5 damage to every enemy within 40px."},
	{"id": "rekindle", "branch": "bruiser", "stage": 3, "tier": 4, "kind": Kind.ULTIMATE,
		"requires": ["molten_armour", "big_heart"],
		"title": "Rekindle", "text": "Rise from the ashes.",
		"facts": "Once per fight, when your health hits 0 you get back up with half your Max Health."},
]

static var _nodes: Array[EmberTreeNode] = []
static var _by_id: Dictionary[String, EmberTreeNode] = {}


static func all_nodes() -> Array[EmberTreeNode]:
	_build_once()
	return _nodes


## The node with this id, or null if there is none.
static func find(id: String) -> EmberTreeNode:
	_build_once()
	return _by_id.get(id)


## The skill node played by the player's node named `action_name` (e.g. "FlameUppercut"),
## or null when no skill node names it. Upgrades and stat nodes that only borrow a
## skill's numbers for their facts (e.g. Kindling) don't count.
static func skill_node_for(action_name: String) -> EmberTreeNode:
	for node in all_nodes():
		if node.kind == Kind.SKILL and node.skill_action == action_name:
			return node
	return null


static func branch_title(branch: String) -> String:
	return BRANCHES[branch]["title"]


static func branch_theme(branch: String) -> String:
	return BRANCHES[branch]["theme"]


static func branch_playstyle(branch: String) -> String:
	return BRANCHES[branch]["playstyle"]


static func branch_angle(branch: String) -> float:
	return BRANCHES[branch]["angle"]


## Every node of one branch, inner ones first.
static func nodes_in_branch(branch: String) -> Array[EmberTreeNode]:
	var branch_nodes: Array[EmberTreeNode] = []
	for node in all_nodes():
		if node.branch == branch:
			branch_nodes.append(node)
	return branch_nodes


static func _build_once() -> void:
	if not _nodes.is_empty():
		return
	for row: Dictionary in NODE_ROWS:
		var node := EmberTreeNode.from_row(row)
		_nodes.append(node)
		_by_id[node.id] = node
