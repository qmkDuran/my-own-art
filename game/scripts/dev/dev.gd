class_name Dev
extends RefCounted
## Playtest tools switch: on with --dev, and in debug builds (the editor, a debug export) unless an automated run
## (tests, shots, videos) is going; never in a release export. Holds the cheat toggles the dev menu flips.

static var god: bool = false            ## the Lamplighter takes no damage
static var one_hit: bool = false        ## every hit kills
static var show_boxes: bool = false     ## draw bodies' collision circles
static var show_light: bool = false     ## draw every light's gameplay radius


const AUTOMATED: Array[String] = ["--smoke", "--layout", "--ui", "--shots", "--probe", "--balance", "--replay", "--animreel",
	"--perf", "--demo", "--demo2", "--demo3"]


static func enabled() -> bool:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--dev"):
		return true
	return OS.is_debug_build() and not AUTOMATED.any(func(a: String) -> bool: return args.has(a))


## The repo's playtest/ folder (notes and session logs are committed from there).
static func playtest_dir(sub: String) -> String:
	var dir: String = ProjectSettings.globalize_path("res://").path_join("../playtest").path_join(sub).simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	return dir


static func stamp() -> String:
	return Time.get_datetime_string_from_system().replace(":", "-")
