class_name SpinTurn
extends RefCounted
## Fakes a full turn on the spot (the Spinning Hook) with the views already drawn, so no
## spin sheets are needed: front, then round through the right-facing views to the back,
## and on through the same views mirrored (facing left) to the front again.
##
## While a spin is shown, this decides the view and mirroring instead of the creature's
## facing, and which frame of the borrowed sheet (the jab's) is held in each view.

## The views of one full turn, in order, and whether each is mirrored (facing left).
const TURN_VIEWS: Array[String] = ["front", "frontdiag", "side", "backdiag", "back", "backdiag", "side", "frontdiag"]
const TURN_FLIPS: Array[bool] = [false, false, false, false, false, true, true, true]
## The view held once the turn is complete.
const END_VIEW := "front"
## Seconds the whole turn takes. The hook lands (SpinningHook.hit_delay, 0.18s) as the
## turn reaches the back; the rest of the spin is spent settling, facing front.
const TURN_SECONDS := 0.34
## Frames of the jab sheet held while turning (fist out) and once settled (recovery).
const TURNING_FRAME := 2
const SETTLED_FRAME := 3
## Drawn for every creature, so it stands in for a view that isn't.
const FALLBACK_VIEW := "side"

var _elapsed: float = 0.0


## Starts the turn again from the front.
func restart() -> void:
	_elapsed = 0.0


func advance(delta: float) -> void:
	_elapsed += delta


func view() -> String:
	return TURN_VIEWS[_step()] if _is_turning() else END_VIEW


func is_flipped() -> bool:
	return TURN_FLIPS[_step()] if _is_turning() else false


## Shows the turn's current view on `sprite`, holding one frame of `action`'s animation
## (a sheet borrowed from the jab). A view that isn't drawn falls back to the side view.
func pose(sprite: AnimatedSprite2D, action: String) -> void:
	sprite.flip_h = is_flipped()
	var pose_name := SpriteSheetLoader.animation_name_for(action, view())
	if not sprite.sprite_frames.has_animation(pose_name):
		pose_name = SpriteSheetLoader.animation_name_for(action, FALLBACK_VIEW)
		if not sprite.sprite_frames.has_animation(pose_name):
			return
	if sprite.animation != pose_name:
		sprite.animation = pose_name
	sprite.pause()
	sprite.frame = mini(_frame_index(), sprite.sprite_frames.get_frame_count(pose_name) - 1)


## Which frame of the borrowed sheet to hold right now.
func _frame_index() -> int:
	return TURNING_FRAME if _is_turning() else SETTLED_FRAME


func _is_turning() -> bool:
	return _elapsed < TURN_SECONDS


func _step() -> int:
	return mini(floori(_elapsed / TURN_SECONDS * TURN_VIEWS.size()), TURN_VIEWS.size() - 1)
