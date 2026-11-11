class_name TuesdayLoop
extends Node
## The Town of One Tuesday: the clocks strike four every LOOP seconds and the day starts over. Everything alive
## goes back where it stood that morning, whole again; everything that died stays dead, and lamps you lit stay lit.
## The HUD shows the hour (Hud reads `clock_text()`). Once the Mayor is down the loop is broken: the clocks go on
## striking (five, six...) but nothing rewinds, and the HUD reads Wednesday. Every strike tells the campaign
## ("clock_strike"), which is what Wren's side quest waits on.

const LOOP: float = 80.0
const START_MINUTES: float = 15.0 * 60.0     ## the loop runs from three in the afternoon to four
const FLASH := Color(1.6, 1.55, 1.45)
const BROKEN_AT: Array = ["one_tuesday", 4]  ## quest step after which the loop is broken (the Mayor is down)
const FIRST_HOUR: int = 4                    ## the hour every clock in town strikes

var t: float = 0.0
var loops: int = 0
var g: Game


func setup(game: Game) -> void:
	g = game


func broken() -> bool:
	return Session.campaign.past(String(BROKEN_AT[0]), int(BROKEN_AT[1]))


## Minutes past the hour on the town's clocks (0-59).
func minute() -> int:
	return int(60.0 * t / LOOP)


func clock_text() -> String:
	var m: float = START_MINUTES + 60.0 * t / LOOP + (60.0 * loops if broken() else 0.0)
	return "%s  %d:%02d" % ["Wednesday" if broken() else "Tuesday", (int(m / 60.0) - 13) % 12 + 1, int(m) % 60]


func _process(delta: float) -> void:
	t += delta
	if broken() and not Session.campaign.flags.has("loop_broken"):
		Session.campaign.set_flag("loop_broken")             # the townsfolk talk about Wednesday from now on
	if t >= LOOP:
		t = 0.0
		loops += 1
		_strike()


func _strike() -> void:
	Audio.sfx("lamp_lit", -2.0, 0.6)
	Session.campaign.notify("clock_strike", "tuesday")
	if broken():
		g.hud.caption("Four o'clock, and for once the day goes on." if loops == 1
			else "The clocks strike %d. Nobody in town has heard that before." % (FIRST_HOUR + loops - 1))
		return
	g.shift_darkness(FLASH, 0.15, 0.9)
	g.hud.caption("The clocks strike four. Everything hurt is whole again. Everything dead stays dead." if loops == 1
		else "Four o'clock. Again.")
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.rank != "boss":
			e.rewind()
