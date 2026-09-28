extends Control
const Bank = preload("res://scripts/pixel/art_bank.gd")
const Story = preload("res://scripts/pixel/story.gd")
const PAPER := Color("eee9d8")
const MUTED := Color("a6b4bc")
const AMBER := Color("e1bc7c")
var world
var opened := false
var selected := 0
var notice := ""
var notice_time := 0.0
var font: Font
var mobile_mode := false
var active_stick := -1
var virtual_stick_axis := Vector2.ZERO
var sprint_touch := -1
var run_toggle := false
var chrome: Control
var modal: Control
var modal_box: VBoxContainer
var modal_kind := ""
var unit := 1.0
var safe := 20.0
var dev_actor := "deer"
var last_size := Vector2.ZERO
var settings_return := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var readable := FontVariation.new()
	readable.base_font = load("res://art/fonts/NotoSansSC.ttf")
	readable.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 550.0}
	readable.variation_embolden = 0.45
	font = readable
	mobile_mode = OS.has_feature("mobile") or OS.has_feature("android")
	var ui_theme := Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 18
	ui_theme.set_color("font_color","Label",PAPER)
	ui_theme.set_color("font_color","Button",PAPER)
	ui_theme.set_color("font_hover_color","Button",AMBER)
	ui_theme.set_color("font_focus_color","Button",AMBER)
	ui_theme.set_color("font_disabled_color","Button",Color("75808b"))
	for type in ["Button","OptionButton","CheckButton"]:
		ui_theme.set_stylebox("normal",type,box(Color("152430"),Color("52616b"),6))
		ui_theme.set_stylebox("hover",type,box(Color("233644"),AMBER,6))
		ui_theme.set_stylebox("pressed",type,box(Color("3a453e"),AMBER,6))
		ui_theme.set_stylebox("focus",type,box(Color(0,0,0,0),AMBER,6))
	theme = ui_theme
	apply_settings()

func box(bg: Color, border: Color, pad := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	return style

func apply_settings() -> void:
	unit = float(world.settings.values.ui_scale)
	if theme:
		theme.default_font_size = roundi(18*unit)
	if is_instance_valid(modal):
		for text in modal.find_children("*","Label",true,false):
			text.add_theme_font_size_override("font_size",roundi(float(text.get_meta("base_font_size",18))*unit))
	rebuild_chrome()
	queue_redraw()

func notify(message: String) -> void:
	notice = message
	notice_time = 5.0

func _process(delta: float) -> void:
	notice_time = maxf(0,notice_time-delta)
	if size != last_size:
		last_size = size
		if OS.has_feature("mobile"):
			var area := DisplayServer.get_display_safe_area()
			var screen := DisplayServer.window_get_size()
			var inset := maxf(maxf(area.position.x,area.position.y),maxf(screen.x-area.end.x,screen.y-area.end.y))
			safe = maxf(20.0,minf(64.0,inset*size.x/maxf(1.0,screen.x)))
		rebuild_chrome()
		if modal_open():
			layout_modal()
	queue_redraw()

func text_at(message: String,pos: Vector2,color := PAPER,pixels := 18) -> void:
	draw_string_outline(font,pos,message,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(pixels*unit),2,Color("081019"))
	draw_string(font,pos,message,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(pixels*unit),color)

func button(label: String, action: Callable, parent: Node, width := 0.0) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(width,40*unit)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func rebuild_chrome() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(chrome):
		remove_child(chrome)
		chrome.queue_free()
	chrome = Control.new()
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chrome)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",8)
	var top_width := (76.0 if world.mode == "menu" else 300.0) * unit
	top.position = Vector2(maxf(360,size.x-top_width-safe),safe)
	chrome.add_child(top)
	if world.mode != "menu":
		button("行囊",show_inventory,top,66*unit)
		button("手记",show_journal,top,66*unit)
		button("墓园",func(): world.enter_menu(),top,66*unit)
	button("设置",show_settings,top,66*unit)
	if world.mode == "menu":
		var dev := button("DEV",func(): world.click_dev(),chrome,68)
		dev.position = Vector2(safe,size.y-safe-44)
	elif world.mode == "dev":
		var dev := button("测试器",show_tester,chrome,100)
		dev.position = Vector2(safe,92)
	var destinations := HBoxContainer.new()
	destinations.add_theme_constant_override("separation",5)
	destinations.position = Vector2(maxf(200,size.x/2-220),72)
	chrome.add_child(destinations)
	if world.mode == "game":
		for id in Story.ACTORS:
			var b := button(Story.REGIONS[id].name,func(): world.travel(id),destinations,70*unit)
			b.disabled = world.region == id
	# Touch actions are native Controls; joystick alone handles motion events.
	if mobile_mode and not modal_open():
		var act := button("调查",func(): world.interact(),chrome,78)
		act.position = Vector2(size.x-safe-86,size.y-safe-160)
		act.custom_minimum_size = Vector2(86,78)
		var sprint := button("疾行 ✓" if run_toggle else "疾行",func():
			run_toggle = not run_toggle
			world.player.touch_run = run_toggle
			rebuild_chrome(),chrome,90)
		sprint.position = Vector2(size.x-safe-194,size.y-safe-106)
		sprint.custom_minimum_size.y = 56
	if is_instance_valid(modal):
		move_child(modal,get_child_count()-1)

func _draw() -> void:
	if font == null or world == null:
		return
	var w := size.x
	var h := size.y
	if world.mode == "menu":
		text_at("鸦 羽 人",Vector2(42,66),AMBER,24)
		text_at("CROWFEATHER",Vector2(40,112),PAPER,42)
		text_at("雾保留了所有未被抹去的名字",Vector2(44,143),MUTED,16)
		for i in range(world.graves.size()):
			var screen: Vector2 = world.graves[i].get_global_transform_with_canvas().origin
			var selected_grave: bool = world.nearest_grave == i+1
			text_at("墓碑 %02d" % (i+1),screen+Vector2(-32,28),AMBER if selected_grave else PAPER,16)
			if selected_grave:
				draw_arc(screen+Vector2(0,2),24,0,TAU,32,AMBER,1.0)
	else:
		text_at("测试房 · 不保存" if world.mode=="dev" else Story.REGIONS[world.region].name,Vector2(safe,44),AMBER,26)
		text_at("抹去 %d  /  顺应 %d  /  畸变 %d" % [world.session.story.erased,world.session.story.accepted,world.session.story.distortion],Vector2(safe,73),MUTED,15)
		if not mobile_mode:
			for i in range(8):
				var rect := slot_rect(i)
				draw_style_box(box(Color("111d29"),AMBER if i==selected else Color("435565"),3),rect)
				var slot = world.inventory.get_slot(i)
				if not slot.is_empty():
					draw_texture_rect(slot.item.icon,Rect2(rect.position+Vector2(3,1),Vector2(28,28)),false)
					text_at(str(slot.quantity),rect.position+Vector2(24,36),AMBER,12)
				text_at(str(i+1),rect.position+Vector2(3,12),MUTED,10)
	if mobile_mode and not modal_open():
		var center := stick_center()
		draw_circle(center,58,Color(0.04,0.08,0.13,0.75))
		draw_arc(center,58,0,TAU,40,Color("667c8e"),2)
		draw_circle(center+virtual_stick_axis*32,20,Color("b8c7c8"))
	if world.settings.values.show_hints and not modal_open():
		var hint_rect := Rect2(w-safe-370,h-safe-(46 if mobile_mode else 80),370,46 if mobile_mode else 80)
		draw_style_box(box(Color(0.035,0.065,0.10,0.92),Color("354953"),8),hint_rect)
		if mobile_mode:
			text_at("左侧移动 · 右侧调查 / 疾行",hint_rect.position+Vector2(12,29),PAPER,16)
		else:
			text_at("WASD 移动   Shift 疾行   E 调查",hint_rect.position+Vector2(12,25),PAPER,16)
			text_at("靠近墓碑选择旅程   Esc 设置" if world.mode=="menu" else "I 行囊   J 手记   Q 放下   Esc 设置",hint_rect.position+Vector2(12,52),MUTED,16)
	if notice_time>0 and not modal_open():
		var line := notice.left(44)
		draw_style_box(box(Color(0.035,0.07,0.10,0.94),Color("485c65"),8),Rect2(safe,159,minf(w-2*safe,780),42))
		text_at(line,Vector2(safe+12,187),PAPER,17)
	if not modal_open():
		var prompt := ""
		if world.nearest_grave>0:
			prompt = "调查墓碑 %02d" % world.nearest_grave
		elif not world.nearest_actor.is_empty():
			prompt = "调查 · " + Story.NAMES[world.nearest_actor]
		elif is_instance_valid(world.nearest_pickup):
			prompt = "拾取 · "+world.nearest_pickup.get_meta("item").item_name
		if not prompt.is_empty():
			text_at(prompt+("  [E]" if not mobile_mode else ""),Vector2(w/2-95,h-112),AMBER,18)

func slot_rect(i: int, _expanded := false) -> Rect2:
	return Rect2(safe+i*42*unit,size.y-safe-46*unit,38*unit,40*unit)

func modal_open() -> bool:
	return is_instance_valid(modal)

func release_touch() -> void:
	active_stick=-1
	sprint_touch=-1
	virtual_stick_axis=Vector2.ZERO
	run_toggle=false
	if is_instance_valid(world.player):
		world.player.touch_direction=Vector2.ZERO
		world.player.touch_run=false

func close_modal() -> void:
	if modal_kind == "dialogue" and world.mode == "game":
		for actor in world.characters.values():
			if actor.state == "talk":
				actor.set_state("corpse")
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal=null
	modal_kind=""
	opened=false
	world.player.input_locked=world.ritual_timer>0
	world.player.investigating=false
	release_touch()
	rebuild_chrome()

func start_modal(title: String, kind: String) -> VBoxContainer:
	close_modal()
	modal_kind=kind
	world.player.input_locked=true
	world.player.velocity=Vector2.ZERO
	modal=Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(modal)
	var shade:=ColorRect.new()
	shade.color=Color(0.01,0.02,0.04,0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var panel:=PanelContainer.new()
	panel.name="Panel"
	panel.add_theme_stylebox_override("panel",box(Color("101c28"),Color("8c886d"),20))
	modal.add_child(panel)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	panel.add_child(root)
	var row:=HBoxContainer.new()
	root.add_child(row)
	var heading:=label(title,row,25)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button("返回",close_modal,row,70)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	modal_box=VBoxContainer.new()
	modal_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_box.add_theme_constant_override("separation",12)
	scroll.add_child(modal_box)
	layout_modal()
	rebuild_chrome()
	return modal_box

func layout_modal() -> void:
	if not modal_open():
		return
	var panel: Control=modal.get_node("Panel")
	var width:=minf(size.x-safe*2,820*unit)
	var height:=minf(size.y-safe*2,480*unit)
	panel.position=Vector2((size.x-width)/2,(size.y-height)/2)
	panel.size=Vector2(width,height)

func label(content: String,parent: Node,pixels:=18) -> Label:
	var l:=Label.new()
	l.text=content
	l.set_meta("base_font_size",pixels)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size",roundi(pixels*unit))
	l.add_theme_color_override("font_color",PAPER)
	l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func show_grave(id: int) -> void:
	var body:=start_modal("墓碑 %02d · 一段被记住的旅程" % id,"grave")
	var desc: String = world.saves.summary(id)
	label(desc,body,22)
	label("每座墓碑保存独立的背包、遗物、区域、位置与因果裁决。旅途会自动保存。",body)
	var exists: bool=not world.saves.read_slot(id).is_empty()
	var b:=button("继续这段旅程" if exists else "在此留下名字 · 开始",func(): world.open_slot(id),body)
	b.disabled=not world.saves.last_error.is_empty()
	if exists:
		label("这座墓碑已有记录，继续会保留全部已作出的选择。",body,16)

func toggle() -> void:
	if opened: close_modal()
	else: show_inventory()

func show_inventory() -> void:
	if world.mode=="menu": return
	var body:=start_modal("行囊 · 遗物与未完的故事","inventory")
	opened=true
	var grid:=GridContainer.new()
	grid.columns=4
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	body.add_child(grid)
	for i in range(8):
		var slot=world.inventory.get_slot(i)
		var title: String="空位" if slot.is_empty() else slot.item.item_name+" × "+str(slot.quantity)
		var b:=button("%d  %s" % [i+1,title],func(): selected=i; show_inventory(),grid,155*unit)
		b.custom_minimum_size.y=54*unit
		if i==selected:
			b.add_theme_color_override("font_color",AMBER)
	var chosen=world.inventory.get_slot(selected)
	if not chosen.is_empty():
		label(chosen.item.item_name,body,23)
		label(chosen.item.description,body)
		button("放下一件 · Q",func(): world.drop_selected(); show_inventory(),body)
	else:
		label("路上总会留下些什么。",body)

func show_settings() -> void:
	var body:=start_modal("设置","settings")
	label("舒适与可读性",body,23)
	for row in [["reduce_motion","关闭动态环境（雾、水面、鸦群 / 固定镜头）"],["reduce_flashes","柔和光效（压低抹去发光与雾幕亮度）"],["show_hints","显示右下角操作提示"]]:
		var setting_row := HBoxContainer.new()
		setting_row.add_theme_constant_override("separation",12)
		body.add_child(setting_row)
		label(row[1],setting_row,18)
		var check:=CheckButton.new()
		check.custom_minimum_size.x=72
		check.tooltip_text=row[1]
		check.button_pressed=world.settings.values[row[0]]
		check.custom_minimum_size.y=42*unit
		check.toggled.connect(func(value): world.settings.set_value(row[0],value))
		setting_row.add_child(check)
	add_slider(body,"UI 大小","ui_scale",0.85,1.3,0.05)
	label("声音",body,23)
	add_slider(body,"BGM 音量","bgm",0,1,0.05)
	add_slider(body,"音效音量","sfx",0,1,0.05)
	button("试听音效",func(): world.sounds.chime(),body)
	label("显示",body,23)
	if OS.has_feature("mobile"):
		label("移动设备跟随屏幕尺寸与横屏安全区域。",body)
	else:
		var modes:=OptionButton.new()
		for s in ["窗口化","窗口化全屏","独占全屏"]: modes.add_item(s)
		modes.select(int(world.settings.values.window_mode))
		modes.item_selected.connect(func(i): world.settings.set_value("window_mode",i))
		body.add_child(modes)
		var resolutions:=OptionButton.new()
		for s in ["1280 × 720","1600 × 900","1920 × 1080","960 × 540"]: resolutions.add_item(s)
		resolutions.select(int(world.settings.values.resolution))
		resolutions.item_selected.connect(func(i): world.settings.set_value("resolution",i))
		body.add_child(resolutions)
		label("分辨率调整应用于窗口模式；全屏使用显示器原生尺寸。",body,16)

func add_slider(parent: Node,title: String,key: String,minimum: float,maximum: float,step: float) -> void:
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var caption:=label(title+"  "+str(roundi(float(world.settings.values[key])*100))+"%",row,18)
	caption.custom_minimum_size.x=220*unit
	var slider:=HSlider.new()
	slider.min_value=minimum
	slider.max_value=maximum
	slider.step=step
	slider.value=world.settings.values[key]
	slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y=42
	row.add_child(slider)
	slider.value_changed.connect(func(v):
		caption.text=title+"  "+str(roundi(v*100))+"%"
		world.settings.set_value(key,v)
		layout_modal())

func show_character(id: String) -> void:
	var body:=start_modal(Story.NAMES[id]+" · 遗物与裁决","character")
	world.player.investigating=true
	var picture:=TextureRect.new()
	picture.texture=Bank.texture(id,8)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size=Vector2(450,190)
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(picture)
	label(Story.TEXT[id],body)
	var verdict: String=world.session.story.decisions.get(id,"")
	if not verdict.is_empty():
		label("已抹去其存在。" if verdict=="erased" else "死亡已成为定局，名字仍被保留。",body,21)
		return
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	body.add_child(row)
	button("让他死 · 留下名字",func(): confirm_judgment(id,false),row,260*unit)
	button("抹去 · 改变因果",func(): confirm_judgment(id,true),row,260*unit)
	button("倾听生前碎念",func(): show_dialogue(id),body)

func show_dialogue(id: String) -> void:
	var body:=start_modal(Story.NAMES[id]+" · 留在雾里的声音","dialogue")
	var picture:=TextureRect.new()
	picture.texture=Bank.texture(id,1)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size.y=160
	body.add_child(picture)
	label("哥们，消息总得有人送到。" if id=="horse" else ("咯咯声很轻。谷粒落在石板上，仍没有被吃完。" if id=="chicken" else Story.TEXT[id].split("\n")[0]),body,22)
	world.characters[id].set_state("talk")
	button("继续调查",func(): world.characters[id].set_state("corpse"); show_character(id),body)

func confirm_judgment(id: String,erase: bool) -> void:
	var body:=start_modal("确认裁决","verdict")
	label(("抹去 %s 的存在" if erase else "让 %s 的死亡成为定局") % Story.NAMES[id],body,26)
	label("这个选择会立即记录在当前墓碑中，并改变后续线索。" if world.mode=="game" else "此为测试房，只改变临时状态。",body)
	label("角色会逐渐发光化雾，雾幕收拢后散去。" if erase else "保留其生前行为及死后影响，留下墓碑。",body)
	button("确认 · "+("抹去" if erase else "顺应死亡"),func(): world.judge(id,erase),body)
	button("重新调查",func(): show_character(id),body)

func show_journal() -> void:
	var body:=start_modal("手记 · 因果之路","journal")
	var node: Dictionary=world.story.graph.get(world.session.story.node,{})
	label(node.get("title","第一夜"),body,26)
	label(node.get("text",""),body,20)
	var ending: String=world.story.ending()
	if world.session.story.node=="self":
		label("终局 · "+ending,body,26)
		label("纯白中，鸦羽人失去了最后的锚点。" if ending=="因果坍塌" else ("留下的剪影提着灯，在浓雾边缘静静引路。" if ending=="顺应宿命" else "仍有名字留在雾中。你带着它们走向下一夜。"),body,20)
	for id in world.session.story.decisions:
		label(Story.NAMES[id]+"："+("抹去" if world.session.story.decisions[id]=="erased" else "顺应死亡"),body,18)
	if not world.story.available().is_empty():
		button("沿线索继续",func(): world.request_story_step(),body)
	else:
		label("继续调查各地死者，新的道路将随裁决展开。",body,16)

func show_tester() -> void:
	if world.mode!="dev": return
	var body:=start_modal("测试器 · 所有操作均不写入游戏存档","tester")
	var actors:=HBoxContainer.new()
	body.add_child(actors)
	for id in Story.ACTORS:
		button(Story.NAMES[id],func(): dev_actor=id; show_tester(),actors,100)
	label("当前角色："+Story.NAMES[dev_actor],body,22)
	var states:=GridContainer.new()
	states.columns=3
	body.add_child(states)
	for row in [["idle","站立"],["talk","对话"],["walk","行走"],["death","死亡"],["corpse","遗体"],["tomb","墓碑"]]:
		button(row[1],func(): world.characters[dev_actor].visible=true; world.characters[dev_actor].set_state(row[0]); close_modal(),states,180)
	button("遗体高清特写 / 裁决",func(): show_character(dev_actor),body)
	button("重置全部角色与因果",func(): world.enter_dev(),body)
	label("区域雾色（累计抹去继续影响全局色调）",body,20)
	var colors:=HBoxContainer.new()
	body.add_child(colors)
	for id in Story.ACTORS:
		button(Story.REGIONS[id].name,func(): world.region=id; close_modal(),colors,100)
	button("测试乌鸦与抹去 Shader",func():
		world.characters[dev_actor].visible=true
		world.characters[dev_actor].set_state("corpse")
		world.session.story.decisions.erase(dev_actor)
		world.judge(dev_actor,true),body)
	button("剧情 / DeepSeek 接口测试",show_director_tester,body)
	button("切换手机触控预览",func(): mobile_mode=not mobile_mode; close_modal(),body)
	button("尝试写入存档（应被阻止）",func():
		var blocked: bool=not world.saves.write_slot(1,world.snapshot())
		notify("PASS：测试房写入被阻止" if blocked else "FAIL：写入保护失效")
		close_modal(),body)

func show_director_tester() -> void:
	var body:=start_modal("剧情与 Agent 测试","director")
	label("当前节点："+str(world.session.story.node),body)
	label("合法后继："+str(world.story.available()),body)
	label("接口离线；只允许从已编写的合法后继节点中选择。",body)
	button("模拟合法建议",func():
		var allowed: Array=world.story.available()
		if not allowed.is_empty():
			world.advance_story({"node":allowed[0],"reason":"测试房模拟"})
		show_director_tester(),body)
	button("模拟非法 / 超时回退",func():
		world.advance_story({"node":"invented_forbidden_branch"})
		show_director_tester(),body)
	label(world.director.last_reason,body)
	button("返回测试器",show_tester,body)

func stick_center() -> Vector2:
	return Vector2(safe+74,size.y-safe-112)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not modal_open() and not mobile_mode:
		if world.mode!="menu":
			for i in range(8):
				if slot_rect(i).has_point(event.position):
					selected=i
					get_viewport().set_input_as_handled()
	if not mobile_mode:
		return
	if event is InputEventScreenTouch:
		if not event.pressed and event.index==active_stick:
			active_stick=-1
			virtual_stick_axis=Vector2.ZERO
			world.player.touch_direction=Vector2.ZERO
			return
		if modal_open():
			return
		if event.pressed and active_stick==-1 and event.position.distance_to(stick_center())<78:
			active_stick=event.index
			update_stick(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==active_stick:
		if modal_open():
			release_touch()
		else:
			update_stick(event.position)
		get_viewport().set_input_as_handled()

func update_stick(pos: Vector2) -> void:
	virtual_stick_axis=((pos-stick_center())/58.0).limit_length(1)
	world.player.touch_direction=virtual_stick_axis
