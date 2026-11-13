class_name SoundSynth
## Synthesises the town's sounds from data/audio.json into 16-bit mono AudioStreamWAVs: an occasional distant
## cricket, the fountain's trickle, a music box tune drifting from a window, rain, footsteps on each surface and
## the effect sounds. No audio files are needed.

const FULL_SCALE: float = 32767.0
const HEADROOM: float = 0.85
const A4_NOTE: int = 69
const A4_HZ: float = 440.0
const SEMITONES: float = 12.0
const BEATS_PER_NOTE: float = 0.5
const SECONDS_PER_MINUTE: float = 60.0
const CHIME_DIP_SPEED: float = 4.0 ## the chime's pitch settles over a quarter second
const CLICK_RATE_SHARE: float = 400.0 ## a crackle click lasts 1/400 of a second
const DROP_PITCH_SHARES: Vector2 = Vector2(0.25, 0.4) ## raindrop pitch as shares of the mix rate
const CRICKET_LEVEL: float = 0.3
const BURST_LEVELS: Vector2 = Vector2(0.1, 0.4)
const BURST_DECAY_SPANS: float = 4.0 ## a burst lasts this many decay times
const BURST_CHIRP: float = 4.0 ## how fast a burst's pitch rises


## One short distant cricket call (a couple of chirps), played now and then from somewhere out in the dark.
static func cricket_chirp() -> AudioStreamWAV:
	var spec: Dictionary = _spec("crickets")
	var samples := PackedFloat32Array()
	samples.resize(_length(spec["seconds"]))
	_cricket(samples, spec)
	var wav: AudioStreamWAV = _to_wav(samples)
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


## A footstep on a surface (data/audio.json steps): a short burst of filtered noise (the scuff) over a soft low
## knock (the heel), each surface with its own brightness, length and body.
static func footstep(surface: String) -> AudioStreamWAV:
	var spec: Dictionary = Tuning.doc("audio")["steps"][surface]
	var rate: float = _rate()
	var samples: PackedFloat32Array = _filtered_noise(_length(spec["seconds"]), spec["cutoff"], spec["level"])
	for n: int in samples.size():
		var t: float = n / rate
		var knock: float = sin(TAU * float(spec["thump_hz"]) * t) * float(spec["thump"])
		samples[n] = (samples[n] + knock) * exp(-t * float(spec["decay"]))
	var wav: AudioStreamWAV = _to_wav(samples)
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


static func trickle() -> AudioStreamWAV:
	var spec: Dictionary = _spec("trickle")
	var samples: PackedFloat32Array = _filtered_noise(_length(spec["seconds"]), spec["cutoff"], spec["noise_level"])
	_add_bursts(samples, spec["bubbles_per_second"], spec["bubble_min"], spec["bubble_max"], spec["bubble_decay"])
	return _to_wav(samples)


static func rain() -> AudioStreamWAV:
	var spec: Dictionary = _spec("rain")
	var samples: PackedFloat32Array = _filtered_noise(_length(spec["seconds"]), spec["cutoff"], spec["noise_level"])
	var rate: float = _rate()
	var pitch: Vector2 = DROP_PITCH_SHARES * rate
	_add_bursts(samples, spec["drops_per_second"], pitch.x, pitch.y, spec["drop_decay"])
	return _to_wav(samples)


## A music box: each note a decaying sine with a soft octave harmonic; 0 is a rest.
static func music_box() -> AudioStreamWAV:
	var spec: Dictionary = _spec("music")
	var notes: Array = spec["notes"]
	var note_seconds: float = SECONDS_PER_MINUTE / float(spec["bpm"]) * BEATS_PER_NOTE
	var note_length: int = _length(note_seconds)
	var samples := PackedFloat32Array()
	samples.resize(note_length * notes.size())
	var rate: float = _rate()
	for index: int in notes.size():
		if int(notes[index]) == 0:
			continue
		var hz: float = A4_HZ * pow(2.0, (int(notes[index]) - A4_NOTE) / SEMITONES)
		for n: int in samples.size() - index * note_length:
			var t: float = n / rate
			var tone: float = sin(TAU * hz * t) + sin(TAU * hz * 2.0 * t) * float(spec["harmonic"])
			samples[index * note_length + n] += tone * exp(-t * float(spec["decay"])) * 0.5
	return _to_wav(samples)


## A short effect sound by name, by its data type: whoosh (a rising filtered breath), chime (a warm chime that dips
## in pitch), crackle (a tail of soft clicks), pluck (a bright tick that drops), thump (a soft low boom), shimmer
## (a quick rising run of bell notes) or swell (a long rising breath with a climbing tone).
static func effect(sound: String) -> AudioStreamWAV:
	var spec: Dictionary = _spec(sound)
	var samples := PackedFloat32Array()
	samples.resize(_length(spec["seconds"]))
	match String(spec["type"]):
		"whoosh":
			_whoosh(samples, spec)
		"chime":
			_chime(samples, spec)
		"pluck", "thump":
			_drop(samples, spec)
		"shimmer":
			_shimmer(samples, spec)
		"swell":
			_swell(samples, spec)
		_:
			_crackle(samples, spec)
	var wav: AudioStreamWAV = _to_wav(samples)
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


## A sine that falls in pitch and fades fast (a bright pluck high up, a soft thump low down).
static func _drop(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	var phase: float = 0.0
	for n: int in samples.size():
		var t: float = n / rate
		var hz: float = float(spec["hz"]) * (1.0 - float(spec["drop"]) * minf(t * CHIME_DIP_SPEED, 1.0))
		phase += TAU * hz / rate
		samples[n] = sin(phase) * exp(-t * float(spec["decay"])) * float(spec["level"])


## A run of bell notes, one every step seconds, each a decaying sine with an octave.
static func _shimmer(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	var notes: Array = spec["notes"]
	for index: int in notes.size():
		var start: int = int(index * float(spec["step"]) * rate)
		var hz: float = A4_HZ * pow(2.0, (int(notes[index]) - A4_NOTE) / SEMITONES)
		for n: int in samples.size() - start:
			var t: float = n / rate
			var tone: float = sin(TAU * hz * t) + sin(TAU * hz * 2.0 * t) * 0.5
			samples[start + n] += tone * exp(-t * float(spec["decay"])) * float(spec["level"]) * 0.5


## Filtered noise opening up over the sound, under a tone gliding upwards: the build-up of a charge.
static func _swell(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	var low: float = 0.0
	var phase: float = 0.0
	for n: int in samples.size():
		var share: float = float(n) / samples.size()
		low += (randf_range(-1.0, 1.0) - low) * lerpf(spec["cutoff_from"], spec["cutoff_to"], share)
		phase += TAU * lerpf(spec["hz_from"], spec["hz_to"], share * share) / rate
		var shape: float = share * sqrt(1.0 - share)
		samples[n] = (low + sin(phase) * 0.5) * shape * float(spec["level"])


static func _whoosh(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var low: float = 0.0
	for n: int in samples.size():
		var t: float = float(n) / samples.size()
		low += (randf_range(-1.0, 1.0) - low) * lerpf(spec["cutoff_from"], spec["cutoff_to"], t)
		samples[n] = low * sin(PI * t) * float(spec["level"])


static func _chime(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	var partials: Array = spec["partials"]
	for n: int in samples.size():
		var t: float = n / rate
		var hz: float = float(spec["hz"]) * (1.0 - float(spec["drop"]) * minf(t * CHIME_DIP_SPEED, 1.0))
		var tone: float = 0.0
		for index: int in partials.size():
			tone += sin(TAU * hz * float(partials[index]) * t) / (index + 1)
		samples[n] = tone * exp(-t * float(spec["decay"]))


static func _crackle(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	for click: int in int(spec["clicks"]):
		var at: int = int(pow(randf(), 2.0) * (samples.size() - 1))
		var loud: float = exp(-float(at) / rate * float(spec["decay"])) * float(spec["level"])
		var length: float = rate / CLICK_RATE_SHARE
		for n: int in mini(int(length), samples.size() - at):
			samples[at + n] += randf_range(-1.0, 1.0) * loud * (1.0 - n / length)


## A few chirps of one cricket: each a quick run of pulses of a high sine.
static func _cricket(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	var pitch: float = randf_range(spec["pitch_min"], spec["pitch_max"])
	var pulse: int = int(rate / float(spec["pulse_rate"]))
	for chirp: int in int(spec["chirps"]):
		var start: int = int(chirp * float(spec["chirp_gap"]) * rate)
		for p: int in int(spec["pulses"]):
			for n: int in pulse / 2:
				var at: int = start + p * pulse + n
				if at < samples.size():
					samples[at] += sin(TAU * pitch * n / rate) * sin(PI * n / (pulse / 2.0)) * CRICKET_LEVEL


static func _filtered_noise(length: int, cutoff: float, level: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(length)
	var low: float = 0.0
	for n: int in length:
		low += (randf_range(-1.0, 1.0) - low) * cutoff
		samples[n] = low * level
	return samples


## Short decaying sine blips at random times (bubbles, raindrops).
static func _add_bursts(samples: PackedFloat32Array, per_second: float, hz_min: float, hz_max: float,
		decay: float) -> void:
	var rate: float = _rate()
	var count: int = int(per_second * samples.size() / rate)
	var span: int = int(rate * BURST_DECAY_SPANS / decay)
	for burst: int in count:
		var at: int = randi() % samples.size()
		var hz: float = randf_range(hz_min, hz_max)
		var loud: float = randf_range(BURST_LEVELS.x, BURST_LEVELS.y)
		for n: int in span:
			var t: float = n / rate
			samples[(at + n) % samples.size()] += sin(TAU * hz * t * (1.0 + t * BURST_CHIRP)) * exp(-t * decay) * loud


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var peak: float = 0.0
	for value: float in samples:
		peak = maxf(peak, absf(value))
	var gain: float = HEADROOM / maxf(peak, 1.0)
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for n: int in samples.size():
		bytes.encode_s16(n * 2, int(clampf(samples[n] * gain, -1.0, 1.0) * FULL_SCALE))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(_rate())
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples.size()
	wav.data = bytes
	return wav


static func _spec(sound: String) -> Dictionary:
	return Tuning.doc("audio")[sound]


static func _rate() -> float:
	return float(Tuning.doc("audio")["mix_rate"])


static func _length(seconds: float) -> int:
	return int(seconds * _rate())
