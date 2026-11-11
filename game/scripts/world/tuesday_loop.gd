class_name TuesdayLoop
extends Node
## The Town of One Tuesday: the clocks strike four every LOOP seconds and the day starts over. Everything alive
## goes back where it stood that morning, whole again; everything that died stays dead, and lamps you lit stay lit.
## The HUD shows the hour (Hud reads `clock_text()`).

const LOOP: float = 80.0
const START_MINUTES: float = 15.0 * 60.0     ## the loop runs from three in the afternoon to four
const FLASH := Color(0.95, 0.92, 0.85)

var t: float = 0.0
var loops: int = 0
var g: Game


func setup(game: Game) -> void:
	g = game


func clock_text() -> String:
	var m: float = START_MINUTES + 60.0 * t / LOOP
	return "Tuesday  %d:%02d" % [int(m / 60.0) - 12, int(m) % 60]


func _process(delta: float) -> void:
	t += delta
	if t >= LOOP:
		t = 0.0
		loops += 1
		_strike()


func _strike() -> void:
	Audio.sfx("lamp_lit", -2.0, 0.6)
	g.shift_darkness(FLASH, 0.15, 0.9)
	g.hud.caption("The clocks strike four. Everything hurt is whole again. Everything dead stays dead." if loops == 1
		else "Four o'clock. Again.")
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var e := n as Enemy
		if e.rank != "boss":
			e.rewind()
