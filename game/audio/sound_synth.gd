class_name SoundSynth
## Synthesises the ambience loops from data/audio.json into 16-bit mono AudioStreamWAVs: crickets, the fountain's
## trickle, a music box tune drifting from a window, and rain. No audio files are needed.

const FULL_SCALE: float = 32767.0
const HEADROOM: float = 0.85
const A4_NOTE: int = 69
const A4_HZ: float = 440.0
const SEMITONES: float = 12.0
const BEATS_PER_NOTE: float = 0.5
const SECONDS_PER_MINUTE: float = 60.0
const DROP_PITCH_SHARES: Vector2 = Vector2(0.25, 0.4) ## raindrop pitch as shares of the mix rate
const CRICKET_LEVEL: float = 0.3
const BURST_LEVELS: Vector2 = Vector2(0.1, 0.4)
const BURST_DECAY_SPANS: float = 4.0 ## a burst lasts this many decay times
const BURST_CHIRP: float = 4.0 ## how fast a burst's pitch rises


static func crickets() -> AudioStreamWAV:
	var spec: Dictionary = _spec("crickets")
	var samples := PackedFloat32Array()
	samples.resize(_length(spec["seconds"]))
	for voice: int in int(spec["voices"]):
		_cricket(samples, spec)
	return _to_wav(samples)


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


static func _cricket(samples: PackedFloat32Array, spec: Dictionary) -> void:
	var rate: float = _rate()
	var pitch: float = randf_range(spec["pitch_min"], spec["pitch_max"])
	var pulse: int = int(rate / float(spec["pulse_rate"]))
	var start: int = randi() % samples.size()
	while start < samples.size() * 2:
		for p: int in int(spec["pulses"]):
			for n: int in pulse / 2:
				var at: int = (start + p * pulse + n) % samples.size()
				samples[at] += sin(TAU * pitch * n / rate) * sin(PI * n / (pulse / 2.0)) * CRICKET_LEVEL
		start += int(randf_range(spec["gap_min"], spec["gap_max"]) * rate)


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
