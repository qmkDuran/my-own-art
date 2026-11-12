class_name Difficulty
## Easy / Normal / Hard. A level changes only how the bot thinks: its reaction time, how often it re-plans, how
## much noise blurs its choices and how much it uses what it has learned about you. Never life, speed or damage.

const LEVELS: Array[String] = ["easy", "normal", "hard"]

## The chosen level; kept across restarts.
static var level: String = "normal"


static func setting(key: String) -> float:
	return float(Tuning.ai["difficulty"][level][key])
