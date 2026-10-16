extends Node
## AudioManager (autoload name: `AudioManager`).
##
## The project ships **no external audio files**. Every sound effect, the music
## loops and the ambience beds are synthesised into `AudioStreamWAV` buffers at
## startup. That keeps the repository dependency-free and licence-clean while
## still giving the game a real soundtrack of chopping, washing, sizzling and
## reward chimes.
##
## To replace a placeholder with a recorded asset:
##   1. drop the file into `res://assets/audio/`
##   2. add a line to `_load_overrides()` below, e.g.
##        overrides["chop"] = preload("res://assets/audio/chop.ogg")
## See docs/PLACEHOLDER_ASSETS.md.

const SAMPLE_RATE := 22050

var _streams: Dictionary = {}
var _fx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _next_fx := 0

## Public list of sound names so tests can assert the whole set exists.
const SFX_NAMES: Array[String] = [
	"chop", "wash", "scrub", "stir", "sizzle", "bubble", "pour", "sprinkle",
	"tap_ok", "tap_bad", "star", "star_full", "level_complete", "paper",
	"sweep", "pop", "ui_click", "ui_back", "page", "error_soft",
]
const MUSIC_NAMES: Array[String] = ["menu", "kitchen", "result"]
const AMBIENCE_NAMES: Array[String] = ["kitchen", "village"]

## False under `--headless`, where the dummy audio driver never releases the
## `AudioStreamPlaybackWAV` objects it creates. Starting playback there is
## pointless (nothing can be heard) and makes the engine report leaked audio
## instances at exit, which would mask real leaks in CI.
var playback_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	_generate_all()
	_setup_players()
	Settings.apply_audio()
	playback_enabled = DisplayServer.get_name() != "headless"
	Game.state_changed.connect(_on_game_state_changed)


func _exit_tree() -> void:
	# Stop looping audio and drop every stream reference so the procedurally
	# generated AudioStreamWAV/playback objects are released on shutdown.
	stop_all()
	if _music_player != null:
		_music_player.stream = null
	if _ambience_player != null:
		_ambience_player.stream = null
	if _ui_player != null:
		_ui_player.stream = null
	for p in _fx_players:
		p.stream = null


# ------------------------------------------------------------------- buses ---
func _setup_buses() -> void:
	# Master always exists at index 0.
	for bus_name in [Settings.BUS_MUSIC, Settings.BUS_SFX, Settings.BUS_UI]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			AudioServer.add_bus()
			idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, Settings.BUS_MASTER)
			AudioServer.set_bus_volume_db(idx, 0.0)


# ----------------------------------------------------------------- players ---
func _setup_players() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = Settings.BUS_SFX
		add_child(p)
		_fx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = Settings.BUS_MUSIC
	_music_player.volume_db = -8.0
	add_child(_music_player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = Settings.BUS_SFX
	_ambience_player.volume_db = -18.0
	add_child(_ambience_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = Settings.BUS_UI
	_ui_player.volume_db = -3.0
	add_child(_ui_player)


# ------------------------------------------------------------------ public ---
## Plays a sound effect. `pitch_variation` randomises pitch a little, which is
## what keeps repeated chops and scrubs from sounding mechanical.
func play_sfx(name: String, pitch_variation: float = 0.0, volume_db: float = 0.0) -> void:
	if not _streams.has(name):
		push_warning("AudioManager: unknown sfx '%s'." % name)
		return
	if not playback_enabled:
		return
	var player := _fx_players[_next_fx]
	_next_fx = (_next_fx + 1) % _fx_players.size()
	player.stream = _streams[name]
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.volume_db = volume_db
	player.play()


## Interface clicks use their own player so a burst of kitchen effects can never
## swallow a button press.
func play_ui(name: String) -> void:
	if not _streams.has(name):
		push_warning("AudioManager: unknown ui sfx '%s'." % name)
		return
	if not playback_enabled:
		return
	_ui_player.stream = _streams[name]
	_ui_player.pitch_scale = 1.0
	_ui_player.volume_db = -3.0
	_ui_player.play()


func play_music(name: String) -> void:
	if not _streams.has(name):
		push_warning("AudioManager: unknown music '%s'." % name)
		return
	if not playback_enabled:
		return
	if _music_player.stream == _streams[name] and _music_player.playing:
		return
	_music_player.stream = _streams[name]
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_ambience(name: String) -> void:
	if not _streams.has(name):
		push_warning("AudioManager: unknown ambience '%s'." % name)
		return
	if not playback_enabled:
		return
	if _ambience_player.stream == _streams[name] and _ambience_player.playing:
		return
	_ambience_player.stream = _streams[name]
	_ambience_player.play()


func stop_ambience() -> void:
	_ambience_player.stop()


func stop_all() -> void:
	stop_music()
	stop_ambience()
	for p in _fx_players:
		p.stop()
	if _ui_player != null:
		_ui_player.stop()


func has_stream(name: String) -> bool:
	return _streams.has(name)


func _on_game_state_changed(state: int, _previous: int) -> void:
	match state:
		Game.State.PLAYING:
			play_music("kitchen")
			play_ambience("kitchen")
		Game.State.RESULT:
			play_music("result")
			stop_ambience()
		Game.State.MENU, Game.State.LEVEL_SELECT, Game.State.JOURNAL, Game.State.ASSESSMENT, Game.State.SOURCES:
			play_music("menu")
			stop_ambience()
		_:
			pass


# --------------------------------------------------------------- generation ---
func _generate_all() -> void:
	# Replace any of these keys with real recordings if assets become available.
	var overrides := _load_overrides()
	for name in SFX_NAMES:
		_streams[name] = overrides.get(name, _synth_sfx(name))
	for name in MUSIC_NAMES:
		_streams[name] = overrides.get(name, _synth_music(name))
	for name in AMBIENCE_NAMES:
		_streams[name] = overrides.get(name, _synth_ambience(name))


func _load_overrides() -> Dictionary:
	var overrides := {}
	# Placeholder asset hooks — uncomment and point at real files when available.
	# overrides["chop"] = preload("res://assets/audio/chop.ogg")
	# overrides["menu"] = preload("res://assets/audio/menu_theme.ogg")
	return overrides


func _synth_sfx(name: String) -> AudioStreamWAV:
	match name:
		"chop":
			return _wav(_chop(0.16), 0.95)
		"wash":
			return _wav(_noise_burst(0.36, 1500.0, 0.32, 0.0, 1.0), 1.0)
		"scrub":
			return _wav(_noise_burst(0.30, 2400.0, 0.26, 0.0, 0.8), 1.0)
		"stir":
			return _wav(_noise_burst(0.34, 900.0, 0.18, 0.0, 1.0), 1.0)
		"sizzle":
			return _wav(_noise_burst(0.55, 4200.0, 0.16, 0.0, 1.0), 1.0)
		"bubble":
			return _wav(_sweep(0.20, 240.0, 620.0, 0.26, "sine"), 1.0)
		"pour":
			return _wav(_noise_burst(0.55, 2000.0, 0.22, 0.0, 1.0), 1.0)
		"sprinkle":
			return _wav(_sprinkle(0.42), 0.9)
		"tap_ok":
			return _wav(_bell(0.20, 1046.5, 0.28), 0.85)
		"tap_bad":
			return _wav(_sweep(0.26, 420.0, 190.0, 0.28, "triangle"), 0.95)
		"star":
			return _wav(_bell(0.26, 1318.5, 0.28), 0.85)
		"star_full":
			return _wav(_arpeggio([880.0, 1108.7, 1318.5, 1760.0], 0.10, 0.30), 0.9)
		"level_complete":
			return _wav(_arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.14, 0.32), 0.9)
		"paper":
			return _wav(_noise_burst(0.20, 3200.0, 0.20, 0.0, 1.0), 1.0)
		"sweep":
			return _wav(_noise_burst(0.34, 2600.0, 0.24, 0.0, 0.9), 1.0)
		"pop":
			return _wav(_bell(0.12, 700.0, 0.26), 0.8)
		"error_soft":
			return _wav(_arpeggio([392.0, 329.63], 0.13, 0.24), 0.9)
		"ui_click":
			return _wav(_bell(0.07, 1568.0, 0.22), 0.7)
		"ui_back":
			return _wav(_bell(0.09, 660.0, 0.22), 0.7)
		"page":
			return _wav(_noise_burst(0.14, 3000.0, 0.18, 0.0, 1.0), 1.0)
		_:
			return _wav(_bell(0.1, 440.0, 0.2), 1.0)


func _synth_music(name: String) -> AudioStreamWAV:
	match name:
		"menu":
			return _looping(_melody_loop(92.0, [0, 3, 5, 7, 5, 3, 0, -2], 261.63, 0.14))
		"kitchen":
			return _looping(_melody_loop(104.0, [0, 2, 4, 7, 9, 7, 4, 2], 293.66, 0.13))
		"result":
			return _looping(_melody_loop(112.0, [0, 4, 7, 9, 7, 4, 2, 0], 329.63, 0.13))
		_:
			return _looping(_melody_loop(100.0, [0, 4, 7], 261.63, 0.12))


func _synth_ambience(name: String) -> AudioStreamWAV:
	match name:
		"kitchen":
			return _looping(_noise_bed(4.0, 520.0, 0.42, 0.10))
		"village":
			return _looping(_noise_bed(4.0, 340.0, 0.48, 0.12))
		_:
			return _looping(_noise_bed(3.0, 500.0, 0.5, 0.08))


# ------------------------------------------------------------- dsp helpers ---
## A knife hitting a board: a short noise transient plus a woody body.
func _chop(duration: float) -> PackedFloat32Array:
	var n := _samples(duration)
	var out := _zero(n)
	var transient := _noise_burst(0.05, 2600.0, 0.55, 0.0, 1.0)
	var body := _bell(duration, 220.0, 0.30)
	for i in n:
		var v := 0.0
		if i < transient.size():
			v += transient[i]
		if i < body.size():
			v += body[i]
		out[i] = v
	return out


## Several tiny chimes in quick succession: seasoning falling into a pan.
func _sprinkle(duration: float) -> PackedFloat32Array:
	var n := _samples(duration)
	var out := _zero(n)
	var offsets := [0.0, 0.07, 0.13, 0.20, 0.27, 0.33]
	var freqs := [1760.0, 2093.0, 1568.0, 2349.3, 1975.5, 2637.0]
	for k in offsets.size():
		var start := int(offsets[k] * SAMPLE_RATE)
		var seg := _bell(0.14, freqs[k], 0.22)
		for i in seg.size():
			var idx := start + i
			if idx >= n:
				break
			out[idx] += seg[i]
	return out


## Constant-power-ish envelope: quick attack, exponential-ish decay.
func _env(t: float, duration: float, attack: float = 0.01) -> float:
	if t < attack:
		return t / maxf(attack, 0.0001)
	var x := (t - attack) / maxf(duration - attack, 0.0001)
	return pow(maxf(0.0, 1.0 - x), 1.8)


func _zero(n: int) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(n)
	a.fill(0.0)
	return a


func _samples(duration: float) -> int:
	return maxi(1, int(duration * SAMPLE_RATE))


func _bell(duration: float, freq: float, amp: float) -> PackedFloat32Array:
	var n := _samples(duration)
	var out := _zero(n)
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var e := _env(t, duration, 0.004)
		var v := sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.01 * t) * 0.2 + sin(TAU * freq * 3.03 * t) * 0.1
		out[i] = v * e * amp
	return out


func _sweep(duration: float, f0: float, f1: float, amp: float, shape: String) -> PackedFloat32Array:
	var n := _samples(duration)
	var out := _zero(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f: float = lerpf(f0, f1, t)
		phase += TAU * f / SAMPLE_RATE
		var v := 0.0
		match shape:
			"triangle":
				v = asin(sin(phase)) * 0.6366
			_:
				v = sin(phase)
		out[i] = v * _env(float(i) / SAMPLE_RATE, duration, 0.005) * amp
	return out


func _arpeggio(freqs: Array, step: float, amp: float) -> PackedFloat32Array:
	var total := step * freqs.size() + 0.25
	var n := _samples(total)
	var out := _zero(n)
	for fi in freqs.size():
		var freq: float = freqs[fi]
		var start := int(fi * step * SAMPLE_RATE)
		var len_notes := _samples(step + 0.24)
		for i in len_notes:
			var idx := start + i
			if idx >= n:
				break
			var t := float(i) / SAMPLE_RATE
			var e := _env(t, step + 0.24, 0.004)
			var v := sin(TAU * freq * t) * 0.75 + sin(TAU * freq * 2.0 * t) * 0.25
			out[idx] += v * e * amp
	return out


func _noise_burst(duration: float, cutoff: float, amp: float, _unused: float, decay: float = 1.0) -> PackedFloat32Array:
	var n := _samples(duration)
	var out := _zero(n)
	# One-pole low-pass over white noise gives us water, chop and wipe textures
	# cheaply and deterministically enough for a placeholder.
	var alpha: float = clampf(TAU * cutoff / SAMPLE_RATE, 0.0, 1.0)
	var prev := 0.0
	for i in n:
		var white := randf_range(-1.0, 1.0)
		prev = prev + alpha * (white - prev)
		var t := float(i) / SAMPLE_RATE
		out[i] = prev * _env(t, duration * decay, 0.003) * amp
	return out


func _noise_bed(duration: float, cutoff: float, amp: float, wobble: float) -> PackedFloat32Array:
	var n := _samples(duration)
	var out := _zero(n)
	var alpha: float = clampf(TAU * cutoff / SAMPLE_RATE, 0.0, 1.0)
	var prev := 0.0
	for i in n:
		var white := randf_range(-1.0, 1.0)
		prev = prev + alpha * (white - prev)
		var t := float(i) / SAMPLE_RATE
		var swell := 1.0 + sin(TAU * t / duration) * wobble
		out[i] = prev * amp * swell
	# Cross-fade the tail into the head so the loop point is inaudible.
	var fade := int(0.25 * SAMPLE_RATE)
	for i in fade:
		var w := float(i) / float(fade)
		out[i] = lerpf(out[n - fade + i], out[i], w)
	return out


## Builds a short, loopable pentatonic tune. The scale is deliberately
## pentatonic so it reads as South-East Asian folk rather than Western pop.
func _melody_loop(bpm: float, steps: Array, root: float, amp: float) -> PackedFloat32Array:
	var beat := 60.0 / bpm / 2.0
	var total := beat * steps.size() * 2.0
	var n := _samples(total)
	var out := _zero(n)
	var scale := [0.0, 2.0, 3.0, 5.0, 7.0, 9.0, 10.0, 12.0]

	# Melody: two passes (call / response) so the loop has shape.
	for pass_index in 2:
		for s in steps.size():
			var degree := int(steps[s])
			var semitone: float = scale[posmod(degree, scale.size())]
			var freq := root * pow(2.0, semitone / 12.0)
			if pass_index == 1:
				freq *= 1.0 if s % 3 != 0 else 1.5
			var start := int((pass_index * steps.size() + s) * beat * SAMPLE_RATE)
			_blit_note(out, start, beat * 0.9, freq, amp)
	# Simple bass on every other beat.
	var bass_steps := steps.size() * 2
	for s in bass_steps:
		if s % 2 != 0:
			continue
		var freq := root / 2.0 * (1.5 if s % 4 == 0 else 1.0)
		_blit_note(out, int(s * beat * SAMPLE_RATE), beat * 1.6, freq, amp * 0.6)
	return out


func _blit_note(out: PackedFloat32Array, start: int, duration: float, freq: float, amp: float) -> void:
	var n := _samples(duration)
	for i in n:
		var idx := start + i
		if idx < 0 or idx >= out.size():
			break
		var t := float(i) / SAMPLE_RATE
		var e := _env(t, duration, 0.008)
		# Karplus-Strong-ish pluck: fundamental plus two quiet odd harmonics.
		var v := sin(TAU * freq * t) * 0.8 + sin(TAU * freq * 2.0 * t) * 0.12 + sin(TAU * freq * 3.0 * t) * 0.06
		out[idx] += v * e * amp


func _wav(samples: PackedFloat32Array, amp: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i] * amp, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav


func _looping(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := _wav(samples, 1.0)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = samples.size()
	return wav
