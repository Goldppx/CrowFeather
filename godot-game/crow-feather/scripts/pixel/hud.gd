extends Control

const Art = preload("res://scripts/pixel/art.gd")
const PAPER := Color("dfd9bd")
const MUTED := Color("829792")
const AMBER := Color("d9ad68")
var world: Node2D
var opened := false
var selected := 0
var notice := "沿着路灯，拾起遗落之物。"
var notice_time := 5.0
var font: SystemFont
var mobile_mode := false
var active_stick := -1
var virtual_actions: Dictionary = {}
var active_touch_actions: Dictionary = {}
var virtual_stick_axis := Vector2.ZERO
const STICK_CENTER := Vector2(70, 276)
const STICK_RADIUS := 47.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	mobile_mode = OS.has_feature("mobile") or OS.has_feature("android")

func _process(delta: float) -> void:
	notice_time = maxf(0, notice_time - delta)
	queue_redraw()

func notify(message: String) -> void:
	notice = message
	notice_time = 3.5

func toggle() -> void:
	opened = not opened
	world.player.input_locked = opened
	if opened:
		world.player.velocity = Vector2.ZERO
	queue_redraw()

func text_at(message: String, pos: Vector2, color: Color = PAPER, font_size: int = 12) -> void:
	draw_string(font, pos + Vector2(1, 1), message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("071116"))
	draw_string(font, pos, message, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func panel(rect: Rect2, border: Color = Color("405856")) -> void:
	draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size), Color(0, 0, 0, 0.45))
	draw_rect(rect, Color("10232a"))
	draw_rect(rect, border, false, 1)
	draw_line(rect.position + Vector2(2, 2), rect.position + Vector2(rect.size.x - 2, 2), Color("213a40"))

func slot_rect(index: int, expanded: bool) -> Rect2:
	if expanded:
		return Rect2(Vector2(140 + (index % 4) * 43, 127 + (index / 4) * 46), Vector2(37, 38))
	return Rect2(Vector2(204 + index * 29, 319), Vector2(26, 27))

func draw_slot(index: int, expanded: bool) -> void:
	var rect := slot_rect(index, expanded)
	panel(rect, AMBER if index == selected else Color("405856"))
	var data = world.inventory.get_slot(index)
	if not data.is_empty():
		draw_texture_rect(data.item.icon, Rect2(rect.position + Vector2(3, 0), rect.size - Vector2(6, 3)), false)
		text_at(str(data.quantity), rect.end - Vector2(12, 3), AMBER, 9)
	elif expanded:
		text_at("·", rect.position + Vector2(16, 23), MUTED)
	if not expanded:
		text_at(str(index + 1), rect.position + Vector2(2, 9), MUTED, 8)

func _draw() -> void:
	if world == null or font == null:
		return
	text_at("C R O W F E A T H E R", Vector2(22, 29), PAPER, 15)
	text_at("鸦 羽 人   /   雾 渡", Vector2(23, 46), MUTED, 10)
	draw_line(Vector2(23, 55), Vector2(164, 55), Color("536c68"))
	text_at("第一夜", Vector2(567, 26), AMBER, 12)
	text_at("旧墓园 · 01", Vector2(547, 42), MUTED, 10)
	text_at("WASD 移动  /  Shift 疾行", Vector2(20, 326), MUTED, 10)
	text_at("E 拾取   I / Tab 背包", Vector2(20, 343), MUTED, 10)
	text_at("Q 丢弃  /  1—8 选格", Vector2(493, 343), MUTED, 10)
	for i in range(8):
		draw_slot(i, false)
	if mobile_mode:
		draw_set_transform(STICK_CENTER, 0, Vector2.ONE)
		draw_circle(Vector2.ZERO, STICK_RADIUS, Color(0.05, 0.11, 0.13, 0.58))
		draw_arc(Vector2.ZERO, STICK_RADIUS, 0.0, TAU, 24, Color("74827a"), 1.0, false)
		draw_circle(virtual_stick_axis * 19.0, 11, Color("9eac9c"))
		draw_set_transform(Vector2.ZERO)
		panel(Rect2(519, 220, 101, 36), Color("827353"))
		text_at("拾 取   E", Vector2(538, 243), AMBER, 11)
		panel(Rect2(519, 308, 101, 36), Color("526a68"))
		text_at("行 囊   I", Vector2(538, 331), PAPER, 11)
		panel(Rect2(120, 290, 61, 39), Color("526a68"))
		text_at("疾 行", Vector2(132, 314), PAPER, 10)
	if notice_time > 0 and not opened:
		text_at(notice, Vector2(22, 76), PAPER, 11)
	if is_instance_valid(world.nearest_pickup) and not opened:
		var item = world.nearest_pickup.get_meta("item")
		panel(Rect2(229, 274, 182, 25))
		text_at("[E] 拾取 " + item.item_name, Vector2(241, 291), AMBER, 11)
	if not opened:
		return
	draw_rect(Rect2(0, 0, 640, 360), Color(0.01, 0.025, 0.035, 0.65))
	panel(Rect2(116, 73, 408, 220), Color("71817a"))
	text_at("行 囊", Vector2(137, 102), PAPER, 18)
	text_at("遗物与未完的故事", Vector2(204, 102), MUTED, 11)
	text_at("[I / Esc] 收起", Vector2(419, 101), MUTED, 10)
	draw_line(Vector2(137, 112), Vector2(503, 112), Color("405856"))
	for i in range(8):
		draw_slot(i, true)
	draw_line(Vector2(321, 127), Vector2(321, 249), Color("405856"))
	var slot = world.inventory.get_slot(selected)
	if slot.is_empty():
		text_at("空置", Vector2(339, 148), MUTED, 16)
		text_at("路上总会留下些什么。", Vector2(339, 174), MUTED, 11)
	else:
		text_at(slot.item.item_name, Vector2(339, 148), AMBER, 16)
		var lines: PackedStringArray = slot.item.description.split("\n")
		for i in range(lines.size()):
			text_at(lines[i], Vector2(339, 171 + i * 17), PAPER, 11)
		text_at("数量  %d / %d" % [slot.quantity, slot.item.slot_max], Vector2(339, 230), MUTED, 11)
		panel(Rect2(338, 247, 163, 26), Color("827353"))
		text_at("[Q] 放下一件", Vector2(369, 264), AMBER, 11)
	text_at("点击格子或按 1—8 选择", Vector2(138, 251), MUTED, 10)
	text_at("物品可堆叠 · 共 8 格", Vector2(138, 270), MUTED, 10)

func _gui_input(event: InputEvent) -> void:
	if mobile_mode:
		if event is InputEventScreenTouch:
			if event.pressed:
				if not opened and event.position.distance_to(STICK_CENTER) <= STICK_RADIUS * 1.45 and active_stick == -1:
					active_stick = event.index
					_update_virtual_stick(event.position)
				elif not opened and Rect2(519, 220, 101, 36).has_point(event.position):
					world.collect_nearest()
				elif Rect2(519, 308, 101, 36).has_point(event.position):
					toggle()
				elif not opened and Rect2(120, 290, 61, 39).has_point(event.position):
					active_touch_actions[event.index] = "RUN"
					_set_virtual_action("RUN", true)
			else:
				if event.index == active_stick:
					active_stick = -1
					_release_virtual_movement()
				if active_touch_actions.has(event.index):
					_set_virtual_action(str(active_touch_actions[event.index]), false)
					active_touch_actions.erase(event.index)
			accept_event()
		elif event is InputEventScreenDrag and event.index == active_stick:
			_update_virtual_stick(event.position)
			accept_event()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(8):
			if slot_rect(i, opened).has_point(event.position):
				selected = i
				accept_event()
		if opened and Rect2(338, 247, 163, 26).has_point(event.position):
			world.drop_selected()
			accept_event()

func _update_virtual_stick(position: Vector2) -> void:
	var axis := ((position - STICK_CENTER) / STICK_RADIUS).limit_length(1.0)
	virtual_stick_axis = axis
	_set_virtual_action("MOVE_RIGHT", axis.x > 0.25)
	_set_virtual_action("MOVE_LEFT", axis.x < -0.25)
	_set_virtual_action("MOVE_BACKWARD", axis.y > 0.25)
	_set_virtual_action("MOVE_FORWARD", axis.y < -0.25)

func _set_virtual_action(action: String, pressed: bool) -> void:
	if bool(virtual_actions.get(action, false)) == pressed:
		return
	virtual_actions[action] = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)

func _release_virtual_movement() -> void:
	virtual_stick_axis = Vector2.ZERO
	for action in ["MOVE_RIGHT", "MOVE_LEFT", "MOVE_FORWARD", "MOVE_BACKWARD"]:
		_set_virtual_action(action, false)
