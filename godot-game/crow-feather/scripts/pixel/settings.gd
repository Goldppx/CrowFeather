extends Node
signal changed
const DEFAULTS := {"reduce_motion": false, "reduce_flashes": true, "show_hints": true, "ui_scale": 1.0, "bgm": 0.45, "sfx": 0.7, "window_mode": 0, "resolution": 0}
const RESOLUTIONS := [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080), Vector2i(960,540)]
var values := DEFAULTS.duplicate()
var path := "user://settings.json"

func _ready() -> void:
	load_values()
	for bus in ["BGM", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	apply(true)

func load_values() -> void:
	if not FileAccess.file_exists(path):
		return
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	if saved is Dictionary:
		for key in DEFAULTS:
			if saved.has(key):
				var v = saved[key]
				if DEFAULTS[key] is bool and v is bool:
					values[key] = v
				elif (DEFAULTS[key] is float or DEFAULTS[key] is int) and (v is float or v is int):
					if is_finite(float(v)):
						values[key] = v
	values.ui_scale = clampf(float(values.ui_scale), 0.85, 1.3)
	values.bgm = clampf(float(values.bgm), 0.0, 1.0)
	values.sfx = clampf(float(values.sfx), 0.0, 1.0)
	values.window_mode = clampi(int(values.window_mode), 0, 2)
	values.resolution = clampi(int(values.resolution), 0, RESOLUTIONS.size()-1)

func set_value(key: String, value: Variant, persist := true) -> void:
	if not DEFAULTS.has(key):
		return
	values[key] = value
	apply(key in ["window_mode", "resolution"])
	if persist:
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(values))
	changed.emit()

func apply(display := false) -> void:
	for entry in [["BGM", "bgm"], ["SFX", "sfx"]]:
		var index := AudioServer.get_bus_index(entry[0])
		if index >= 0:
			var volume := float(values[entry[1]])
			AudioServer.set_bus_mute(index, volume <= 0.001)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	if display and not OS.has_feature("mobile") and DisplayServer.get_name() != "headless":
		var modes := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
		DisplayServer.window_set_mode(modes[int(values.window_mode)])
		if int(values.window_mode) == 0:
			DisplayServer.window_set_size(RESOLUTIONS[int(values.resolution)])
			var usable := DisplayServer.screen_get_usable_rect()
			DisplayServer.window_set_position(usable.position + (usable.size - DisplayServer.window_get_size()) / 2)
