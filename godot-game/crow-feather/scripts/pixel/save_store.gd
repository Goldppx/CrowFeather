extends RefCounted
## Versioned, per-slot, atomic local saves. Sandbox cannot write by construction.
const VERSION := 1
const SLOT_COUNT := 3
var directory := "user://saves"
var sandbox := false
var last_error := ""
var recovered := false

func fresh() -> Dictionary:
	return {"version": VERSION, "region": "deer", "position": [480.0, 360.0],
		"inventory": [], "pickups": [], "world_initialized": false,
		"story": {"node": "arrival", "flags": {}, "erased": 0, "accepted": 0, "distortion": 0, "history": [], "decisions": {}, "branch": "witness"},
		"played_seconds": 0.0, "saved_at": ""}

func path_for(slot: int) -> String:
	return directory.path_join("grave_%d.json" % slot)

func validate(data: Variant) -> bool:
	if not data is Dictionary or int(data.get("version", -1)) != VERSION:
		return false
	if not data.get("story") is Dictionary or not data.get("inventory") is Array or not data.get("pickups") is Array:
		return false
	var p = data.get("position", [])
	if not p is Array or p.size() != 2:
		return false
	for v in p:
		if not (v is float or v is int) or not is_finite(float(v)):
			return false
	var story: Dictionary = data.story
	if not data.get("region") is String or not data.get("saved_at") is String:
		return false
	for key in ["erased","accepted","distortion"]:
		var count = story.get(key)
		if not (count is float or count is int) or not is_finite(float(count)) or float(count) < 0 or float(count) > 100:
			return false
	if not story.get("node") is String or not data.get("played_seconds") is float and not data.get("played_seconds") is int:
		return false
	if story.get("decisions") is Dictionary:
		for id in story.decisions:
			if id not in ["deer","horse","pig","sheep","chicken"] or story.decisions[id] not in ["erased","accepted"]:
				return false
	if story.get("flags") is Dictionary:
		for flag in story.flags:
			if not story.flags[flag] is bool:
				return false
	return story.get("decisions") is Dictionary and story.get("flags") is Dictionary and story.get("history") is Array

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed = parser.data
	return parsed if validate(parsed) else {}

func read_slot(slot: int) -> Dictionary:
	last_error = ""
	recovered = false
	if slot < 1 or slot > SLOT_COUNT:
		last_error = "无效存档位"
		return {}
	var data := _read(path_for(slot))
	if not data.is_empty():
		return data
	data = _read(path_for(slot) + ".bak")
	if not data.is_empty():
		recovered = true
		return data
	if FileAccess.file_exists(path_for(slot)):
		last_error = "存档无法读取，请保留文件并检查备份。"
	return {}

func summary(slot: int) -> String:
	var data := read_slot(slot)
	if data.is_empty():
		return "空白墓碑 · 新旅程" if last_error.is_empty() else "存档损坏 · 请检查备份"
	return "%d 次裁决 · %s%s" % [data.story.decisions.size(), str(data.saved_at).replace("T", " "), " · 已恢复备份" if recovered else ""]

func write_slot(slot: int, data: Dictionary) -> bool:
	last_error = ""
	if sandbox:
		last_error = "测试房禁止写入存档"
		return false
	if slot < 1 or slot > SLOT_COUNT or not validate(data):
		last_error = "存档数据校验失败"
		return false
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if dir_error != OK:
		last_error = "无法创建存档目录"
		return false
	var path := path_for(slot)
	var next := data.duplicate(true)
	next.saved_at = Time.get_datetime_string_from_system()
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		last_error = "无法写入临时存档"
		return false
	f.store_string(JSON.stringify(next, "\t"))
	f.flush()
	f.close()
	if _read(path + ".tmp").is_empty():
		last_error = "写入后的存档校验失败"
		return false
	# Keep the last known-valid save; never replace a healthy backup with corrupt data.
	if not _read(path).is_empty():
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			last_error = "无法备份原存档"
			return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		last_error = "无法提交存档"
		return false
	data.saved_at = next.saved_at
	return true
