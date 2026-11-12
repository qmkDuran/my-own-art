class_name UtilityCurve
## Turns one raw fact (a distance, a 0/1 flag, a life share) into a 0..1 desire, as described in data/ai.json:
## "linear" rises from `from` to `to`, "inverse" falls, "bell" peaks halfway between them. An optional "floor"
## keeps a consideration from ever vetoing an option completely.


static func evaluate(spec: Dictionary, value: float) -> float:
	var t: float = clampf(inverse_lerp(float(spec["from"]), float(spec["to"]), value), 0.0, 1.0)
	var desire: float = t
	match String(spec["curve"]):
		"inverse":
			desire = 1.0 - t
		"bell":
			desire = 1.0 - absf(2.0 * t - 1.0)
	return lerpf(float(spec.get("floor", 0.0)), 1.0, desire)
