class_name LightText
extends RefCounted
## What the Light gauge means right now, in numbers.

static func rows(p: Player) -> Array:
	var L: Dictionary = GameData.light
	var lt: LanternLight = p.light
	return ["Light %d  (radius %d px)" % [roundi(lt.value), roundi(lt.light_radius())],
		["Kills feed it (+%d, more for elites). Hits dim it." % roundi(float(L["kill_gain"])), UiDraw.TEXT],
		["It settles back between %d and %d by itself." % [roundi(float(L["calm_low"])), roundi(float(L["calm_high"]))], UiDraw.TEXT],
		["Blazing at %d+: +%d%% damage." % [roundi(float(L["blazing_at"])), roundi(float(L["blazing_damage_pct"]) + p.stats.v("blazing_pct"))], Pal.c("gold")],
		["Outside the light enemies are Shrouded:", Pal.c("violet_lt")],
		["they take %d%% less and deal %d%% more." % [roundi((1.0 - float(L["shrouded_damage_taken_mult"])) * 100.0),
			roundi((float(L["shrouded_damage_dealt_mult"]) - 1.0) * 100.0)], Pal.c("violet_lt")]]
