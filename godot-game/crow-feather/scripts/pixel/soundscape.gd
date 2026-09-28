extends Node
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var step_clock := 0.0

func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.bus = "BGM"
	add_child(music)
	music.stream = tone(10.0, true)
	music.play()
	effects = AudioStreamPlayer.new()
	effects.bus = "SFX"
	add_child(effects)

func tone(seconds: float, ambient: bool) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / rate
		var value := 0.0
		if ambient:
			value = (sin(TAU * 55.0 * t) * 0.04 + sin(TAU * 82.5 * t) * 0.022 + sin(TAU * 110.0 * t) * 0.012) * (0.75 + 0.25 * sin(TAU * t / seconds))
		else:
			value = (sin(TAU * 330.0 * t) * 0.22 + sin(TAU * 495.0 * t) * 0.05) * exp(-t * 16.0)
		data.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if ambient:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = samples
	return stream

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	if is_instance_valid(effects):
		effects.stop()
		effects.stream = null

func chime() -> void:
	effects.stream = tone(0.4, false)
	effects.play()
