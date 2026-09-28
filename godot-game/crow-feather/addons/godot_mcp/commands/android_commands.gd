@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"list_android_devices": _list_android_devices,
		"deploy_to_android": _deploy_to_android,
		"get_android_build_info": _get_android_build_info,
		"get_android_preset_info": _get_android_preset_info,
	}


func _run_shell(command: String, args: PackedStringArray) -> Dictionary:
	var output: Array = []
	var exit_code := OS.execute(command, args, output, true)
	return {"exit_code": exit_code, "output": "\n".join(PackedStringArray(output)).strip_edges()}


func _read_export_presets() -> Array:
	var path := "res://export_presets.cfg"
	if not FileAccess.file_exists(path):
		return []
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return []
	var presets: Array = []
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			presets.append({
				"name": cfg.get_value(section, "name", section),
				"platform": cfg.get_value(section, "platform", ""),
				"section": section,
				"cfg": cfg,
			})
	return presets


func _find_android_preset(preset_name: String = "") -> Dictionary:
	for preset in _read_export_presets():
		if preset.platform != "Android":
			continue
		if preset_name.is_empty() or preset.name == preset_name:
			return preset
	return {}


func _list_android_devices(_p: Dictionary) -> Dictionary:
	var result := _run_shell("adb", PackedStringArray(["devices"]))
	if result.exit_code != 0:
		return _ok({
			"devices": [],
			"adb_available": false,
			"output": result.output,
			"note": "Install Android SDK platform-tools and ensure adb is in PATH",
		})
	var devices: Array = []
	for line in result.output.split("\n"):
		if line.contains("\tdevice"):
			devices.append(line.split("\t")[0])
	return _ok({"devices": devices, "adb_available": true, "count": devices.size()})


func _get_android_preset_info(p: Dictionary) -> Dictionary:
	var preset_name: String = p.get("preset", "")
	var preset := _find_android_preset(preset_name)
	if preset.is_empty():
		return _err("Android export preset not found")
	var cfg: ConfigFile = preset.cfg
	var options_section: String = str(preset.section) + ".options"
	var options: Dictionary = {}
	if cfg.has_section(options_section):
		for key in cfg.get_section_keys(options_section):
			options[key] = cfg.get_value(options_section, key)
	return _ok({
		"preset": preset.name,
		"platform": preset.platform,
		"export_path": cfg.get_value(preset.section, "export_path", ""),
		"package": options.get("package/unique_name", ProjectSettings.get_setting("application/config/name", "")),
		"version_code": options.get("version/code", ProjectSettings.get_setting("application/config/version", "")),
		"version_name": options.get("version/name", ""),
		"min_sdk": options.get("gradle_build/min_sdk", ""),
		"target_sdk": options.get("gradle_build/target_sdk", ""),
		"architectures": options.get("architectures/arm64-v8a", false),
		"options": options,
	})


func _get_android_build_info(_p: Dictionary) -> Dictionary:
	var preset_info := _get_android_preset_info({})
	if preset_info.has("error"):
		return _ok({
			"package": ProjectSettings.get_setting("application/config/name", ""),
			"version": ProjectSettings.get_setting("application/config/version", ""),
			"min_sdk": ProjectSettings.get_setting("application/config/android_minimum_sdk", ""),
			"target_sdk": ProjectSettings.get_setting("application/config/android_target_sdk", ""),
		})
	return _ok({
		"package": preset_info.package,
		"version": preset_info.version_name,
		"min_sdk": preset_info.min_sdk,
		"target_sdk": preset_info.target_sdk,
	})


func _deploy_to_android(p: Dictionary) -> Dictionary:
	var apk_path: String = p.get("apk_path", "")
	var device_id: String = p.get("device_id", "")
	var preset_name: String = p.get("preset", "Android")
	if apk_path.is_empty() or device_id.is_empty():
		return _err("Provide apk_path and device_id")
	var preset := _find_android_preset(preset_name)
	if preset.is_empty():
		return _err("Android export preset not found")
	var preset_data := _get_android_preset_info({"preset": preset_name})
	if preset_data.has("error"):
		return preset_data
	var export_result := _run_shell("godot", PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--export-debug", preset_name, apk_path]))
	if export_result.exit_code != 0:
		return _err(export_result.output)
	var package_name: String = preset_data.package
	var install_result := _run_shell("adb", PackedStringArray(["-s", device_id, "install", "-r", apk_path]))
	if install_result.exit_code != 0:
		return _err(install_result.output)
	return _ok({"exported": true, "installed": true, "apk_path": apk_path, "preset": preset_name, "package": package_name, "export_output": export_result.output, "install_output": install_result.output})