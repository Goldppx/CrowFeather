extends Node
signal changed
const DEFAULTS := {"reduce_motion": false, "reduce_flashes": true, "show_hints": true, "ui_scale": 1.0, "bgm": 0.45, "sfx": 0.7, "window_mode": 0, "resolution": 0}
var resolutions: Array[Vector2i] = []
var display_error := ""
var native_size := Vector2i(1280,720)
var display_index := -1

func refresh_resolutions() -> void:
	resolutions.clear()
	if DisplayServer.get_name() != "headless":
		display_index = DisplayServer.window_get_current_screen()
		native_size = DisplayServer.screen_get_size(display_index)
	# Window sizes follow the connected screen's aspect and bounds, including its native size.
	for fraction in [0.5,0.625,0.75,0.875,1.0]:
		var candidate := Vector2i(roundi(native_size.x*fraction),roundi(native_size.y*fraction))
		if candidate.x>=640 and candidate.y>=360 and candidate not in resolutions:
			resolutions.append(candidate)
	if resolutions.is_empty(): resolutions.append(native_size)
	values.resolution = clampi(int(values.resolution),0,resolutions.size()-1)

func resolution_labels() -> Array[String]:
	refresh_resolutions()
	var result: Array[String] = []
	for option in resolutions:
		result.append("%d × %d%s" % [option.x,option.y," · 原生" if option==native_size else ""])
	return result

func toggle_fullscreen() -> void:
	set_value("window_mode",2 if int(values.window_mode)==0 else 0)

var values := DEFAULTS.duplicate()
var path := "user://settings.json"

func _ready() -> void:
	load_values()
	refresh_resolutions()
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
	values.resolution = maxi(0,int(values.resolution))

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
	if display:
		apply_display()

func apply_display() -> void:
	display_error = ""
	if OS.has_feature("mobile") or DisplayServer.get_name()=="headless": return
	if "--wid" in OS.get_cmdline_args():
		display_error = "显示模式需在独立游戏窗口中调整。"
		return
	var window := get_window()
	var selected_screen := DisplayServer.window_get_current_screen()
	if selected_screen != display_index: refresh_resolutions()
	var modes := [Window.MODE_WINDOWED,Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]
	window.mode = modes[int(values.window_mode)]
	if int(values.window_mode)==0:
		window.borderless = false
		window.size = resolutions[clampi(int(values.resolution),0,resolutions.size()-1)]
		var usable := DisplayServer.screen_get_usable_rect(selected_screen)
		window.position = usable.position+(usable.size-window.size)/2
	if DisplayServer.window_get_mode()!=modes[int(values.window_mode)]:
		display_error = "当前窗口没有切换成功，请用 F11 重试。"
