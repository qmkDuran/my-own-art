class_name HitStop
extends RefCounted
## Freezes the game for a blink so a hit lands with weight (see HitFeel for the frame counts
## per kind of hit). TimeControl does the freezing.

## Frames of the default freeze (an Intro-sized hit).
const DEFAULT_FRAMES := 6


static func play(tree: SceneTree, frames: int = DEFAULT_FRAMES) -> void:
	TimeControl.of(tree).hit_stop(frames)
