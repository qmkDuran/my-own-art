class_name TalkSystem
extends RefCounted
## Talking with the redeemed: the nearest person within reach turns to the player, shows a bubble,
## and their verse (NIV) appears as the caption.

const REACH: float = 52.0
const SECONDS: float = 6.5
const SOFT_MUSIC_DB: float = -22.0

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
		_captions.say(best.take_quote(), SECONDS)
		if best.has_meta("soften_music"):            # the music softens while he speaks
			Audio.set_music_volume(SOFT_MUSIC_DB, 1.0)
			best.get_tree().create_timer(SECONDS).timeout.connect(func() -> void: Audio.restore_music(1.5))
	return best


func nearest(from: Vector2) -> Npc:
	var best: Npc = null
	for n: Npc in people:
		var d: float = n.global_position.distance_to(from)
		if d < float(n.get_meta("reach", REACH)) and (best == null or d < best.global_position.distance_to(from)):
			best = n
	return best
