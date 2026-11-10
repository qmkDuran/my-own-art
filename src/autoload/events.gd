extends Node
## Global signal bus. Systems announce what happened here; UI, audio and tests listen.

@warning_ignore_start("unused_signal")
signal flag_changed(flag: String, value: Variant)
signal toast(text: String)
signal interact_prompt_changed(text: String)
signal player_health_changed(hp: int, max_hp: int)
signal player_died
signal enemy_defeated(entity_id: String)
signal zone_entered(zone_id: String)
signal dialogue_started(ref: String)
signal dialogue_finished(ref: String)
signal card_shown(kind: String, title: String, subtitle: String)
signal shake_requested(strength: float, duration: float)
signal story_event(name: String)
signal checkpoint_saved
@warning_ignore_restore("unused_signal")
