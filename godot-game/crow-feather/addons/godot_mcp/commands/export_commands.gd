@tool
extends "res://addons/godot_mcp/commands/base_commands.gd"

func get_commands() -> Dictionary:
	return {
		"list_export_presets": _list_export_presets,
		"export_project": _export_project,
		"get_export_info": _get_export_info,
	}


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
				"export_path": cfg.get_value(section, "export_path", ""),
				"section": section,
			})
	return presets


func _list_export_presets(_p: Dictionary) -> Dictionary:
	return _ok({"presets": _read_export_presets()})


func _export_project(p: Dictionary) -> Dictionary:
	var preset_name: String = p.get("preset", "")
	var path: String = p.get("path", "")
	if preset_name.is_empty():
		return _err("Provide preset")
	return _ok({"command": "godot --headless --path <project> --export-release \"%s\" \"%s\"" % [preset_name, path], "note": "Run from shell with Godot 4.6.3 and the matching export templates"})


func _get_export_info(_p: Dictionary) -> Dictionary:
	return _ok({
		"preset_count": _read_export_presets().size(),
		"presets": _read_export_presets(),
		"godot_version": Engine.get_version_info(),
	})