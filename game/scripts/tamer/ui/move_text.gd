class_name MoveText
extends RefCounted
## What a move does, in words and real numbers, for tooltips, the creature info panel and the team station: its
## name, type and element, the sentence from moves.json, then damage (after the creature's power), reach or area,
## what it costs or how it is held, and its effects.

const WRAP: float = 230.0
const KIND_NAMES: Dictionary = {"strike": "Close hit", "bolt": "Skillshot", "lunge": "Dash", "burst": "Area",
	"guard": "Ward", "status": "Hold to channel", "wall": "Wall"}


static func element_of(id: String, user_element: String) -> String:
	return String(TamerData.move(id).get("element", user_element))


## Title line, kind and element, the description (wrapped), then the numbers.
static func rows(ci: CanvasItem, id: String, power: float, user_element: String, key: String = "") -> Array:
	var m: Dictionary = TamerData.move(id)
	var el: String = element_of(id, user_element)
	var out: Array = []
	out.append([("[%s] " % key if key != "" else "") + String(m["name"]), TamerData.color(el, "light")])
	out.append(["%s  -  %s  -  %s" % [String(m["type"]).capitalize(), KIND_NAMES[String(m["kind"])], TamerData.element(el)["name"]], UiDraw.DIM])
	for line: String in UiDraw.wrap(ci, String(m.get("desc", "")), WRAP):
		out.append(line)
	out.append_array(numbers(m, power))
	return out


static func numbers(m: Dictionary, power: float) -> Array:
	var out: Array = []
	var dmg: float = float(m["damage"]) * power
	var hits: int = int(m.get("pulses", m.get("count", 1)))
	if dmg > 0.0:
		out.append(["Damage %d%s" % [roundi(dmg), " x %d" % hits if hits > 1 else ""], UiDraw.GOLD])
	out.append([_reach(m), UiDraw.TEXT])
	out.append([_cost(m), UiDraw.GOLD])
	if m.has("windup"):
		out.append(["Wind-up %.2f s, recovery %.2f s (no dodge)" % [float(m["windup"]), float(m.get("recovery", 0.0))], UiDraw.DIM])
	for e: String in effects(m):
		out.append([e, UiDraw.UP])
	return out


static func _cost(m: Dictionary) -> String:
	match String(m["type"]):
		"physical":
			return "Free: fills the gauge"
		"status":
			return "Hold up to %.1f s to channel: no moving or dodging, a hit cancels it" % float(m["channel"])
	return "Costs %d gauge" % int(m.get("cost", 0))


static func _reach(m: Dictionary) -> String:
	match String(m["kind"]):
		"status":
			return "On itself" if String(m["target"]) == "self" else "On the foe within %d px" % int(m["range"])
		"wall":
			return "%d cells wide, lasts %.0f s" % [int(m["width"]), float(m["duration"])]
		"strike":
			return "Reach %d px, %d deg arc" % [int(m["range"]), int(m.get("arc", 120))]
		"bolt", "lunge":
			return "Range %d px" % int(m["range"])
		"burst":
			return ("Area %d px around it" if String(m.get("at", "aim")) == "self" else "Area %d px at the cursor") % int(m["radius"])
	return "Lasts %.0f s" % float(m.get("duration", 0.0))


static func effects(m: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if float(m.get("stun", 0.0)) > 0.0:
		out.append("Stuns %.1f s" % float(m["stun"]))
	if float(m.get("knock", 0.0)) >= 14.0:
		out.append("Knocks back")
	if m.has("absorb"):
		out.append("Soaks %d damage" % int(m["absorb"]))
	if m.has("heal"):
		out.append("Heals it %d" % int(m["heal"]))
	if bool(m.get("pierce", false)):
		out.append("Pierces")
	if float(m.get("delay", 0.0)) > 0.0:
		out.append("Lands after %.2f s" % float(m["delay"]))
	if m.has("effect"):
		var e: Dictionary = CreatureEffects.data(String(m["effect"]))
		out.append("%s for %.0f s" % [e["name"], float(e["time"])] + ((", then %s" % CreatureEffects.data(String(e["then"]))["name"]) if e.has("then") else ""))
	return out
