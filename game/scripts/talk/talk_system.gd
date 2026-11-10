class_name TalkSystem
extends RefCounted
## Talking with the redeemed: the nearest person within reach turns to the player, shows a bubble,
## and their verse (KJV) appears as the caption.

const REACH: float = 52.0
const SECONDS: float = 5.5

var people: Array[Npc] = []
var _captions: CaptionBar


func _init(captions: CaptionBar) -> void:
	_captions = captions


func add(n: Npc) -> void:
	people.append(n)


## Returns the person spoken to, or null if nobody is near.
func talk(from: Vector2) -> Npc:
	var best: Npc = nearest(from)
	if best != null:
		best.speak(from, SECONDS)
		_captions.say(best.quote, SECONDS)
	return best


func nearest(from: Vector2) -> Npc:
	var best: Npc = null
	for n: Npc in people:
		var d: float = n.global_position.distance_to(from)
		if d < REACH and (best == null or d < best.global_position.distance_to(from)):
			best = n
	return best
