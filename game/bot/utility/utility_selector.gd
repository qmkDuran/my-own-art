class_name UtilitySelector
extends RefCounted
## Scores every option in data/ai.json against the bot's current facts: the option's base weight times each of its
## considerations (a curve over one fact). A little noise (more on Easy) blurs close calls; the option already
## running gets a small bonus (inertia) so the bot does not flicker between two plans.

var last_scores: Dictionary = {}
var _options: Dictionary
var _rng: RandomNumberGenerator


func _init(rng: RandomNumberGenerator) -> void:
	_options = Tuning.ai["options"]
	_rng = rng


## The best option name for these facts; `current` is the option being carried out now and `finished` one that
## just completed (skipped this time, so a finished plan is not restarted on the spot). With nothing worth doing
## the current option stays.
func choose(facts: Dictionary, current: String, noise: float, finished: String) -> String:
	var best: String = current
	var best_score: float = 0.0
	last_scores.clear()
	for option: String in _options:
		if option == finished:
			continue
		var value: float = score(option, facts) * (1.0 + _rng.randf_range(-noise, noise))
		if option == current:
			value *= 1.0 + float(Tuning.ai["inertia"])
		last_scores[option] = value
		if value > best_score:
			best_score = value
			best = option
	return best


func score(option: String, facts: Dictionary) -> float:
	var spec: Dictionary = _options[option]
	var total: float = float(spec["base"])
	for consideration: Dictionary in spec["considerations"]:
		total *= UtilityCurve.evaluate(consideration, float(facts.get(consideration["input"], 0.0)))
	return total
