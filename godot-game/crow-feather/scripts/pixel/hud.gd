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
var title_font: Font
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
var settings_tab := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var readable := FontVariation.new()
	readable.base_font = load("res://art/fonts/NotoSansSC.ttf")
	readable.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 400.0}
	readable.variation_embolden = 0.0
	title_font = load("res://art/fonts/CormorantGaramond.ttf")
	font = readable
	mobile_mode = OS.has_feature("mobile") or OS.has_feature("android")
	var ui_theme := Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 13
	ui_theme.set_color("font_color","Label",PAPER)
	ui_theme.set_color("font_color","Button",PAPER)
	ui_theme.set_color("font_hover_color","Button",AMBER)
	ui_theme.set_color("font_focus_color","Button",AMBER)
	ui_theme.set_color("font_disabled_color","Button",Color("75808b"))
	for type in ["Button","OptionButton","CheckButton"]:
		ui_theme.set_stylebox("normal",type,box(Color("101d24"),Color("435551"),4))
		ui_theme.set_stylebox("hover",type,box(Color("233644"),AMBER,4))
		ui_theme.set_stylebox("pressed",type,box(Color("3a453e"),AMBER,4))
		ui_theme.set_stylebox("focus",type,box(Color(0,0,0,0),AMBER,4))
	var rail := StyleBoxFlat.new()
	rail.bg_color=Color("273c3d")
	rail.content_margin_top=2
	rail.content_margin_bottom=2
	var filled:=rail.duplicate()
	filled.bg_color=Color("a98b56")
	ui_theme.set_stylebox("slider","HSlider",rail)
	ui_theme.set_stylebox("grabber_area","HSlider",filled)
	ui_theme.set_stylebox("grabber_area_highlight","HSlider",filled)
	var handle_image:=Image.create(5,11,false,Image.FORMAT_RGBA8)
	handle_image.fill(AMBER)
	var handle:=ImageTexture.create_from_image(handle_image)
	for icon in ["grabber","grabber_highlight","grabber_disabled"]:
		ui_theme.set_icon(icon,"HSlider",handle)
	theme = ui_theme
	apply_settings()

func box(bg: Color, border: Color, pad := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	return style

func apply_settings() -> void:
	unit = float(world.settings.values.ui_scale)
	if theme:
		theme.default_font_size = roundi(13*unit)
	if is_instance_valid(modal):
		for text in modal.find_children("*","Label",true,false):
			text.add_theme_font_size_override("font_size",roundi(float(text.get_meta("base_font_size",13))*unit))
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
	if modal_open():
		layout_modal()
	queue_redraw()

func text_at(message: String,pos: Vector2,color := PAPER,pixels := 13) -> void:
	draw_string_outline(font,pos,message,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(pixels*unit),1,Color("081019"))
	draw_string(font,pos,message,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(pixels*unit),color)

func button(label: String, action: Callable, parent: Node, width := 0.0) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(width,(38 if mobile_mode else 28)*unit)
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
	var top_width := (56.0 if world.mode == "menu" else 236.0) * unit
	top.position = Vector2(maxf(360,size.x-top_width-safe),safe)
	chrome.add_child(top)
	if world.mode != "menu":
		button("行囊",show_inventory,top,50*unit)
		button("手记",show_journal,top,50*unit)
		button("墓园",func(): world.enter_menu(),top,50*unit)
	button("设置",show_settings,top,50*unit)
	if world.mode == "menu":
		var dev := button("DEV",func(): world.click_dev(),chrome,40)
		dev.position = Vector2(safe,size.y-safe-30)
	elif world.mode == "dev":
		var dev := button("测试器",show_tester,chrome,70)
		dev.position = Vector2(safe,76)
	var destinations := HBoxContainer.new()
	destinations.add_theme_constant_override("separation",5)
	destinations.position = Vector2(maxf(180,size.x/2-190),58)
	chrome.add_child(destinations)
	if world.mode == "game":
		for id in Story.ACTORS:
			var b := button(Story.REGIONS[id].name,func(): world.travel(id),destinations,65*unit)
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
		var title_x := w*0.51
		draw_string(title_font,Vector2(title_x,h*0.27),"CrowFeather",HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(52*unit),PAPER)
		text_at("鸦  羽  人",Vector2(title_x+5,h*0.27+29),AMBER,15)
		text_at("走近墓碑，拾起一段未完的旅程",Vector2(title_x+5,h*0.27+53),MUTED,11)
		for i in range(world.graves.size()):
			if world.nearest_grave==i+1:
				var screen: Vector2 = world.graves[i].get_global_transform_with_canvas().origin
				text_at("旅程 %02d  ·  E 调查" % (i+1),screen+Vector2(-38,22),AMBER,11)
	else:
		text_at("C R O W F E A T H E R",Vector2(safe,32),PAPER,12)
		text_at("试映墓园 · 不保存" if world.mode=="dev" else Story.REGIONS[world.region].name,Vector2(safe,51),AMBER,12)
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
		var hint_width := 236.0*unit
		var hint_pos := Vector2(w-safe-hint_width,h-safe-27)
		draw_rect(Rect2(hint_pos-Vector2(8,14),Vector2(hint_width+16,42)),Color(0.035,0.065,0.075,0.58))
		text_at("左侧移动 · 右侧调查 / 疾行" if mobile_mode else "WASD 移动  /  Shift 疾行  /  E 调查",hint_pos,MUTED,11)
		text_at("靠近墓碑开始旅程" if world.mode=="menu" else "I 行囊  /  J 手记  /  Esc 设置",hint_pos+Vector2(0,19),MUTED,10)
	if notice_time>0 and not modal_open() and world.mode!="menu":
		var line := notice.left(45)
		text_at(line,Vector2(safe,116),MUTED,11)
	if not modal_open():
		var prompt := ""
		if world.nearest_grave>0:
			prompt = "调查墓碑 %02d" % world.nearest_grave
		elif not world.nearest_actor.is_empty():
			prompt = "调查 · " + Story.NAMES[world.nearest_actor]
		elif is_instance_valid(world.nearest_pickup):
			prompt = "拾取 · "+world.nearest_pickup.get_meta("item").item_name
		if not prompt.is_empty():
			text_at(prompt+("  [E]" if not mobile_mode else ""),Vector2(w/2-88,h-82),AMBER,12)

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
	shade.color=Color(0.01,0.02,0.03,0.23 if kind in ["character","dialogue","grave","verdict"] else 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var panel:=PanelContainer.new()
	panel.name="Panel"
	panel.add_theme_stylebox_override("panel",box(Color(0.035,0.07,0.085,0.97),Color("637365"),14))
	modal.add_child(panel)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",9)
	panel.add_child(root)
	var row:=HBoxContainer.new()
	root.add_child(row)
	var heading:=label(title,row,16)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button("×",close_modal,row,28)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	modal_box=VBoxContainer.new()
	modal_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal_box.add_theme_constant_override("separation",9)
	scroll.add_child(modal_box)
	layout_modal()
	rebuild_chrome()
	return modal_box

func layout_modal() -> void:
	if not modal_open():
		return
	var panel: Control=modal.get_node("Panel")
	var is_dialogue := modal_kind in ["character","dialogue","grave","verdict"]
	var width:=minf(size.x-safe*2,(720 if is_dialogue else 630)*unit)
	var height:=minf(size.y-safe*2,(195 if is_dialogue else 340)*unit)
	panel.position=Vector2((size.x-width)/2,size.y-safe-height if is_dialogue else (size.y-height)/2)
	panel.size=Vector2(width,height)

func label(content: String,parent: Node,pixels:=13) -> Label:
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
	label(desc,body,16)
	label("雨还没有停。要继续这段旅程吗？",body)
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
		var b:=button("%d  %s" % [i+1,title],func(): selected=i; show_inventory(),grid,125*unit)
		b.custom_minimum_size.y=44*unit
		if i==selected:
			b.add_theme_color_override("font_color",AMBER)
	var chosen=world.inventory.get_slot(selected)
	if not chosen.is_empty():
		label(chosen.item.item_name,body,16)
		label(chosen.item.description,body)
		button("放下一件 · Q",func(): world.drop_selected(); show_inventory(),body)
	else:
		label("路上总会留下些什么。",body)

func show_settings() -> void:
	var body:=start_modal("设置","settings")
	var tabs:=HBoxContainer.new()
	tabs.add_theme_constant_override("separation",8)
	body.add_child(tabs)
	for i in range(3):
		var tab:=button(["画面","声音","辅助"][i],func(): settings_tab=i; show_settings(),tabs,100*unit)
		if i==settings_tab: tab.add_theme_color_override("font_color",AMBER)
	label("",body,5)
	if settings_tab==0:
		label("显示",body,16)
		if OS.has_feature("mobile"):
			label("跟随设备屏幕与安全区域",body,13)
		else:
			var modes:=OptionButton.new()
			for option in ["窗口化","窗口化全屏","独占全屏"]: modes.add_item(option)
			modes.select(int(world.settings.values.window_mode))
			modes.item_selected.connect(func(i): world.settings.set_value("window_mode",i); show_settings())
			option_row(body,"窗口模式",modes)
			var resolutions:=OptionButton.new()
			for option in world.settings.resolution_labels(): resolutions.add_item(option)
			resolutions.select(int(world.settings.values.resolution))
			resolutions.disabled=int(world.settings.values.window_mode)!=0
			resolutions.item_selected.connect(func(i): world.settings.set_value("resolution",i))
			option_row(body,"窗口分辨率",resolutions)
			label("F11 切换全屏\n全屏原生尺寸：%d × %d" % [world.settings.native_size.x,world.settings.native_size.y],body,11)
			if not world.settings.display_error.is_empty(): label(world.settings.display_error,body,11)
		add_slider(body,"界面大小","ui_scale",0.85,1.3,0.05)
	elif settings_tab==1:
		label("声音",body,16)
		add_slider(body,"背景氛围","bgm",0,1,0.05)
		add_slider(body,"音效","sfx",0,1,0.05)
		button("试听音效",func(): world.sounds.chime(),body)
	else:
		label("舒适与提示",body,16)
		for row in [["reduce_motion","关闭环境运动 / 固定镜头"],["reduce_flashes","关闭抹去强光与仪式雾幕"],["show_hints","显示右下角操作提示"]]:
			var setting_row := HBoxContainer.new()
			setting_row.add_theme_constant_override("separation",12)
			body.add_child(setting_row)
			label(row[1],setting_row,13)
			var toggle:=button("开启" if world.settings.values[row[0]] else "关闭",func(): world.settings.set_value(row[0],not world.settings.values[row[0]]); show_settings(),setting_row,65*unit)
			toggle.add_theme_color_override("font_color",AMBER if world.settings.values[row[0]] else MUTED)
		label("关闭环境运动时，雨滴隐藏，雾、水面与鸦群停留。",body,11)

func option_row(parent: Node, caption: String, control: Control) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	parent.add_child(row)
	var title:=label(caption,row,13)
	title.custom_minimum_size.x=155*unit
	control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.y=34*unit
	row.add_child(control)

func add_slider(parent: Node,title: String,key: String,minimum: float,maximum: float,step: float) -> void:
	var row:=HBoxContainer.new()
	parent.add_child(row)
	var caption:=label(title+"  "+str(roundi(float(world.settings.values[key])*100))+"%",row,13)
	caption.custom_minimum_size.x=155*unit
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
	var body:=start_modal(Story.NAMES[id]+"  /  遗物","character")
	world.player.investigating=true
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	body.add_child(row)
	var picture:=TextureRect.new()
	picture.texture=Bank.texture(id,8)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size=Vector2(145,77)*unit
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(picture)
	var detail := VBoxContainer.new()
	detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	label(Story.TEXT[id],detail,13)
	var verdict: String=world.session.story.decisions.get(id,"")
	if not verdict.is_empty():
		label("这个名字已经消失。" if verdict=="erased" else "名字留下了，死亡亦然。",detail,13)
		return
	var choices:=HBoxContainer.new()
	choices.add_theme_constant_override("separation",8)
	body.add_child(choices)
	button("留下名字",func(): confirm_judgment(id,false),choices,125*unit)
	button("抹去存在",func(): confirm_judgment(id,true),choices,125*unit)
	button("倾听",func(): show_dialogue(id),choices,85*unit)

func show_dialogue(id: String) -> void:
	var body:=start_modal(Story.NAMES[id],"dialogue")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",20)
	body.add_child(row)
	var picture:=TextureRect.new()
	picture.texture=Bank.direction_texture(id,0,0)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	picture.custom_minimum_size=Vector2(65,86)*unit
	row.add_child(picture)
	label("哥们，消息总得有人送到。" if id=="horse" else ("咯咯。\n它歪着头，看着石板上的谷粒。" if id=="chicken" else Story.TEXT[id].split("\n")[0]),row,15)
	world.characters[id].face_toward(world.player.position-world.characters[id].position)
	world.characters[id].set_state("talk")
	button("继续调查  →",func(): world.characters[id].set_state("corpse"); show_character(id),body)

func confirm_judgment(id: String,erase: bool) -> void:
	var body:=start_modal("确认裁决","verdict")
	label(("抹去 %s 的存在" if erase else "让 %s 的死亡成为定局") % Story.NAMES[id],body,18)
	label("这个选择会立即记录在当前墓碑中，并改变后续线索。" if world.mode=="game" else "此为测试房，只改变临时状态。",body)
	label("角色会逐渐发光化雾，雾幕收拢后散去。" if erase else "保留其生前行为及死后影响，留下墓碑。",body)
	button("确认 · "+("抹去" if erase else "顺应死亡"),func(): world.judge(id,erase),body)
	button("重新调查",func(): show_character(id),body)

func show_journal() -> void:
	var body:=start_modal("手记 · 因果之路","journal")
	var node: Dictionary=world.story.graph.get(world.session.story.node,{})
	label(node.get("title","第一夜"),body,18)
	label(node.get("text",""),body,14)
	var ending: String=world.story.ending()
	if world.session.story.node=="self":
		label("终局 · "+ending,body,18)
		label("纯白中，鸦羽人失去了最后的锚点。" if ending=="因果坍塌" else ("留下的剪影提着灯，在浓雾边缘静静引路。" if ending=="顺应宿命" else "仍有名字留在雾中。你带着它们走向下一夜。"),body,14)
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
		button(Story.NAMES[id],func(): dev_actor=id; show_tester(),actors,82)
	label("当前角色："+Story.NAMES[dev_actor],body,15)
	var states:=GridContainer.new()
	states.columns=3
	body.add_child(states)
	for row in [["idle","站立"],["talk","对话"],["walk","行走"],["death","死亡"],["corpse","遗体"],["tomb","墓碑"]]:
		button(row[1],func(): world.characters[dev_actor].visible=true; world.characters[dev_actor].set_state(row[0]); close_modal(),states,140)
	button("遗体特写 / 裁决",func(): show_character(dev_actor),body)
	var directions := HBoxContainer.new()
	body.add_child(directions)
	for i in range(4):
		button(["正面","右侧","背面","左侧"][i],func(): world.characters[dev_actor].direction=i; world.characters[dev_actor].current=-1; close_modal(),directions,90)
	var weather_row := HBoxContainer.new()
	body.add_child(weather_row)
	for preset in ["clear","rain","fog","storm"]:
		button({"clear":"晴夜","rain":"细雨","fog":"浓雾","storm":"雨雾"}[preset],func(): world.weather=preset; close_modal(),weather_row,90)
	button("重置全部角色与因果",func(): world.enter_dev(),body)
	label("区域雾色（累计抹去继续影响全局色调）",body,14)
	var colors:=HBoxContainer.new()
	body.add_child(colors)
	for id in Story.ACTORS:
		button(Story.REGIONS[id].name,func(): world.region=id; close_modal(),colors,80)
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
