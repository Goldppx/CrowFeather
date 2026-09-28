extends "res://scripts/pixel/ground.gd"
const Player = preload("res://scripts/pixel/player.gd")
const HUD = preload("res://scripts/pixel/hud.gd")
const Character = preload("res://scripts/pixel/character.gd")
const Crows = preload("res://scripts/pixel/crows.gd")
const SaveStore = preload("res://scripts/pixel/save_store.gd")
const Settings = preload("res://scripts/pixel/settings.gd")
const Story = preload("res://scripts/pixel/story.gd")
const Director = preload("res://scripts/pixel/director.gd")
const DeepSeekAdapter = preload("res://scripts/pixel/deepseek_adapter.gd")
const Soundscape = preload("res://scripts/pixel/soundscape.gd")
const InventoryModel = preload("res://scripts/items/Inventory.gd")
const ItemData = preload("res://scripts/items/InventoryItemData.gd")
var inventory = InventoryModel.new(8)
var player
var hud
var camera: Camera2D
var atmosphere: ShaderMaterial
var pickups: Array[Node2D] = []
var nearest_pickup: Node2D
var items: Dictionary = {}
var elapsed := 0.0
var fog_clock := 0.0
var settings
var sounds
var saves = SaveStore.new()
var session: Dictionary = {}
var story = Story.new()
var director = Director.new()
var mode := "menu"
var slot_id := 0
var characters: Dictionary = {}
var graves: Array[Node2D] = []
var nearest_grave := 0
var nearest_actor := ""
var crows
var region := "deer"
var autosave_timer := 0.0
var ritual_timer := 0.0
var ritual_actor := ""
var actions: Array = []
var adapter
var pending_story := false
var dev_clicks := 0
var dev_deadline := 0.0
var dirty := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	settings = Settings.new()
	add_child(settings)
	sounds = Soundscape.new()
	add_child(sounds)
	adapter = DeepSeekAdapter.new()
	add_child(adapter)
	adapter.completed.connect(_story_suggestion)
	session = saves.fresh()
	story.bind(session.story)
	_build_ground()
	actors = Node2D.new()
	actors.name = "DepthSorted"
	actors.y_sort_enabled = true
	add_child(actors)
	_build_props()
	_build_water()
	if ResourceLoader.exists("res://art/characters/menu.png"):
		menu_background = load("res://art/characters/menu.png")
	player = Player.new()
	actors.add_child(player)
	camera = Camera2D.new()
	camera.name = "PixelCamera"
	camera.position = Vector2(480,335)
	add_child(camera)
	_build_items()
	_build_characters()
	_build_overlay()
	crows = Crows.new()
	crows.world = self
	add_child(crows)
	settings.changed.connect(_apply_settings)
	inventory.inventory_changed.connect(func(_index): dirty = true)
	inventory.inventory_full.connect(func(_item): hud.notify("行囊已满，先放下一些物品。"))
	get_tree().auto_accept_quit = false
	enter_menu(false)

func _build_items() -> void:
	for row in [["feather","鸦羽","冰冷的羽毛。有人刚经过这里。",12,20],["ember","余烬","握在手里还有微温。路灯似乎需要它。",13,10],["key","旧钥匙","锁孔还记得它。",14,1]]:
		var item = ItemData.new()
		item.id = row[0]
		item.item_name = row[1]
		item.description = row[2]
		item.icon = Art.texture(row[3])
		item.slot_max = row[4]
		item.stackable = row[4] > 1
		items[item.id] = item

func _build_characters() -> void:
	for id in Story.ACTORS:
		var actor = Character.new()
		actor.actor_id = id
		actor.name = "Character_" + id
		actors.add_child(actor)
		characters[id] = actor
	for i in range(3):
		var grave = Character.new()
		grave.actor_id = ["deer","horse","sheep"][i]
		grave.position = Vector2(325+i*155,335-abs(i-1)*12)
		actors.add_child(grave)
		grave.set_state("tomb")
		graves.append(grave)

func _build_overlay() -> void:
	var effects := CanvasLayer.new()
	effects.name = "Atmosphere"
	effects.layer = 5
	add_child(effects)
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere = ShaderMaterial.new()
	atmosphere.shader = load("res://shaders/pixel_atmosphere.gdshader")
	rect.material = atmosphere
	effects.add_child(rect)
	var ui := CanvasLayer.new()
	ui.name = "Interface"
	ui.layer = 10
	add_child(ui)
	hud = HUD.new()
	hud.name = "GameHUD"
	hud.world = self
	ui.add_child(hud)

func _clear_pickups() -> void:
	for item in pickups:
		item.queue_free()
	pickups.clear()
	nearest_pickup = null

func enter_menu(save_first := true) -> void:
	if save_first and mode == "game" and not save_game():
		hud.notify("返回墓园前保存失败：" + saves.last_error)
		return
	_release_inputs()
	mode = "menu"
	slot_id = 0
	saves.sandbox = false
	session = saves.fresh()
	story.bind(session.story)
	region = "deer"
	ritual_timer = 0
	ritual_actor = ""
	_clear_pickups()
	inventory.clear()
	player.position = Vector2(480,414)
	_refresh_room()
	hud.close_modal()
	hud.notify("走近一座墓碑，开始或继续它记录的旅程。")

func open_slot(id: int) -> void:
	var data: Dictionary = saves.read_slot(id)
	if data.is_empty():
		if not saves.last_error.is_empty():
			hud.notify(saves.last_error)
			return
		data = saves.fresh()
		data.story.flags.mail_route = true
	mode = "game"
	slot_id = id
	saves.sandbox = false
	session = data
	story.bind(session.story)
	region = str(session.region) if Story.REGIONS.has(str(session.region)) else "deer"
	inventory.clear()
	for i in range(mini(8,session.inventory.size())):
		var saved = session.inventory[i]
		if saved is Dictionary and items.has(str(saved.get("id",""))):
			var item = items[str(saved.id)]
			var amount := clampi(int(saved.get("quantity",0)),0,int(item.slot_max))
			if amount > 0:
				inventory.slots[i] = InventoryModel.SlotData.new(item,amount)
	_clear_pickups()
	if not bool(session.world_initialized):
		for j in range(5):
			spawn_pickup("feather",Vector2(505,385),3,Story.ACTORS[j])
			spawn_pickup("ember",Vector2(367,365),2,Story.ACTORS[j])
			spawn_pickup("key",Vector2(640,345),1,Story.ACTORS[j])
		session.world_initialized = true
	else:
		for row in session.pickups:
			if row is Dictionary and items.has(str(row.get("id",""))) and row.get("position") is Array and row.position.size() == 2:
				spawn_pickup(str(row.id),Vector2(float(row.position[0]),float(row.position[1])),clampi(int(row.get("amount",1)),1,999),str(row.get("region","deer")))
	player.position = Vector2(clampf(float(session.position[0]),115,838),clampf(float(session.position[1]),200,565))
	_refresh_room()
	hud.close_modal()
	dirty = true
	save_game()
	hud.notify("已读取墓碑 %d。靠近死者调查遗物。" % id)

func enter_dev() -> void:
	if mode == "game" and not save_game():
		return
	_release_inputs()
	mode = "dev"
	slot_id = 0
	saves.sandbox = true
	session = saves.fresh()
	session.story.flags.mail_route = true
	story.bind(session.story)
	region = "deer"
	_clear_pickups()
	inventory.clear()
	for id in items:
		inventory.add_item(items[id],1)
		spawn_pickup(id,Vector2(400+pickups.size()*38,390),3,region)
	player.position = Vector2(480,425)
	_refresh_room()
	hud.close_modal()
	hud.notify("测试房：动画、裁决、区域色板、分支和背包。此房间不会保存。")

func click_dev() -> void:
	if mode != "menu":
		return
	if elapsed > dev_deadline:
		dev_clicks = 0
	dev_clicks += 1
	dev_deadline = elapsed + 2.0
	hud.notify("DEV %d / 3" % dev_clicks)
	if dev_clicks >= 3:
		dev_clicks = 0
		enter_dev()

func _refresh_room() -> void:
	cinematic_menu = mode == "menu"
	for wall in blockers:
		wall.collision_layer = 0 if mode == "menu" else 1
	for prop in scenery:
		prop.visible = mode != "menu"
		prop.collision_layer = 0 if mode == "menu" else 1
	if has_node("Water"):
		get_node("Water").visible = mode != "menu"
	for grave in graves:
		grave.visible = mode == "menu"
		grave.foot_body.collision_layer = 1 if mode == "menu" else 0
	for i in range(Story.ACTORS.size()):
		var id: String = Story.ACTORS[i]
		var actor = characters[id]
		actor.position = Vector2(245+i*116,315) if mode == "dev" else Vector2(493,288)
		actor.visible = mode == "dev" or (mode == "game" and id == region)
		actor.reduce_flashes = settings.values.reduce_flashes
		var verdict: String = session.story.decisions.get(id,"")
		actor.set_state("idle" if mode == "dev" else ("tomb" if verdict == "accepted" else "corpse"))
		if verdict == "erased":
			actor.visible = false
	for pickup in pickups:
		pickup.visible = mode != "menu" and (mode == "dev" or pickup.get_meta("region") == region)
	if is_instance_valid(crows):
		crows.target = Vector2(480,245) if mode == "menu" else Vector2(493,288)
	_apply_settings()
	queue_redraw()
	if is_instance_valid(hud):
		hud.rebuild_chrome()

func travel(id: String) -> void:
	if mode == "menu" or not Story.REGIONS.has(id) or ritual_timer > 0:
		return
	region = id
	session.region = id
	player.position = Vector2(480,383)
	_release_inputs()
	_refresh_room()
	dirty = true
	save_game()
	hud.notify(Story.REGIONS[id].name + " · " + Story.NAMES[id] + "所在之处")

func _process(delta: float) -> void:
	elapsed += delta
	if mode == "menu":
		player.position = player.position.clamp(Vector2(170,320),Vector2(795,545))
	if not settings.values.reduce_motion:
		fog_clock += delta
	if mode == "game":
		session.played_seconds += delta
		autosave_timer += delta
		if autosave_timer >= 12.0:
			autosave_timer = 0
			save_game()
	if ritual_timer > 0:
		ritual_timer = maxf(0.0,ritual_timer-delta)
		if ritual_timer == 0:
			_refresh_room()
			player.investigating = false
			player.input_locked = hud.modal_open()
			save_game()
	var fixed := mode != "game" or bool(settings.values.reduce_motion)
	camera.zoom = Vector2.ONE if fixed else Vector2(1.2,1.2)
	camera.position = Vector2(480,335) if fixed else Vector2(clampf(player.position.x,450,510),clampf(player.position.y,315,370)).round()
	var palette: Dictionary = Story.REGIONS[region]
	var erased := float(session.story.erased)
	var distortion := float(session.story.distortion)
	var target_fog: Color = palette.fog.lerp(Color("d8d7cf"),clampf(erased/5.0,0.0,1.0)*0.75)
	var fog_now = atmosphere.get_shader_parameter("fog_color")
	atmosphere.set_shader_parameter("fog_color",Color(fog_now).lerp(target_fog,minf(1,delta*0.8)) if fog_now != null else target_fog)
	atmosphere.set_shader_parameter("fog_strength",0.16+distortion*0.018)
	atmosphere.set_shader_parameter("motion_clock",fog_clock)
	get_node("Water").material.set_shader_parameter("motion_clock",fog_clock)
	atmosphere.set_shader_parameter("gentle",settings.values.reduce_flashes)
	atmosphere.set_shader_parameter("ritual",sin((1.0-ritual_timer/3.2)*PI) if ritual_timer>0 else 0.0)
	atmosphere.set_shader_parameter("viewport_size",get_viewport_rect().size)
	atmosphere.set_shader_parameter("camera_origin",camera.position-get_viewport_rect().size/2)
	ground_color = ground_color.lerp(palette.ground,minf(1,delta*0.8))
	nearest_pickup = null
	nearest_actor = ""
	nearest_grave = 0
	var closest := 34.0
	for pickup in pickups:
		if not pickup.visible:
			continue
		pickup.get_node("Icon").position.y = -11 if settings.values.reduce_motion else -11+sin(elapsed*2)*1.5
		var distance: float = player.position.distance_to(pickup.position)
		if distance < closest:
			closest = distance
			nearest_pickup = pickup
	if mode == "menu":
		for i in range(graves.size()):
			if player.position.distance_to(graves[i].position) < 62:
				nearest_grave = i+1
	else:
		closest = 66.0
		for id in characters:
			var actor = characters[id]
			if actor.visible and player.position.distance_to(actor.position) < closest:
				closest = player.position.distance_to(actor.position)
				nearest_actor = id
	queue_redraw()

func _draw() -> void:
	super._draw()
	if mode == "game":
		# These props are causal evidence: they disappear only when their owner is erased.
		if bool(session.story.flags.get("mail_route",true)):
			draw_rect(Rect2(688,265,14,24),Color("345263"))
			draw_rect(Rect2(686,260,18,9),Color("a88357"))
		if bool(session.story.flags.get("market_open",true)):
			draw_rect(Rect2(312,390,38,10),Color("794a4d"))
		if bool(session.story.flags.get("bell_remembered",true)):
			draw_circle(Vector2(570,252),5,Color("bdad7d"))

func spawn_pickup(id: String, pos: Vector2, amount: int, area := "") -> Node2D:
	if not items.has(id):
		return null
	var node := Node2D.new()
	node.position = pos
	node.set_meta("item",items[id])
	node.set_meta("amount",amount)
	node.set_meta("region",region if area.is_empty() else area)
	var sprite := Sprite2D.new()
	sprite.name = "Icon"
	sprite.texture = items[id].icon
	sprite.scale = Vector2.ONE*25.0/sprite.texture.get_width()
	sprite.position.y = -11
	node.add_child(sprite)
	actors.add_child(node)
	pickups.append(node)
	return node

func interact() -> void:
	if hud.modal_open() or ritual_timer>0:
		return
	if mode == "menu":
		if nearest_grave>0:
			hud.show_grave(nearest_grave)
		else:
			hud.notify("走近一座墓碑，按 E 或调查键。")
	elif not nearest_actor.is_empty():
		hud.show_character(nearest_actor)
	elif is_instance_valid(nearest_pickup):
		collect_nearest()
	else:
		hud.notify("走近遗物或死者，再调查。")

func collect_nearest() -> void:
	if not is_instance_valid(nearest_pickup):
		return
	var item = nearest_pickup.get_meta("item")
	var quantity: int = nearest_pickup.get_meta("amount")
	var added: int = inventory.add_item(item,quantity)
	if added>0:
		hud.notify("拾取 %s × %d" % [item.item_name,added])
		sounds.chime()
	if added==quantity:
		pickups.erase(nearest_pickup)
		nearest_pickup.queue_free()
		nearest_pickup=null
	else:
		nearest_pickup.set_meta("amount",quantity-added)
	actions.append("拾取"+item.id)
	dirty = true
	save_game()

func drop_selected() -> void:
	var slot = inventory.get_slot(hud.selected)
	if slot.is_empty() or mode == "menu":
		return
	var item = slot.item
	if inventory.remove_item(hud.selected,1)==1:
		spawn_pickup(item.id,player.position,1)
		hud.notify("放下了"+item.item_name)
	dirty = true
	save_game()

func judge(id: String, erase: bool) -> void:
	if mode == "menu" or ritual_timer>0 or not story.judge(id,erase):
		return
	hud.close_modal()
	actions.append(("抹去" if erase else "顺应死亡")+id)
	if erase:
		ritual_actor=id
		ritual_timer=3.2
		characters[id].erase()
		player.input_locked=true
		player.investigating=true
	else:
		characters[id].set_state("tomb")
	sounds.chime()
	dirty=true
	# Decision is durable immediately, even if the application suspends mid-ritual.
	save_game()
	hud.notify("因果已改变。打开手记查看后续。" if erase else "死亡成为定局，名字被留下。")

func advance_story(simulated: Variant = null) -> bool:
	var target: String = director.choose(story,actions,simulated)
	if target.is_empty():
		return false
	if not story.advance(target):
		return false
	dirty=true
	save_game()
	return true

func request_story_step() -> void:
	if pending_story:
		return
	if not adapter.enabled:
		advance_story()
		hud.show_journal()
		return
	var context: Dictionary = director.context(story,actions)
	context.slot_id = slot_id
	context.mode = mode
	pending_story = true
	adapter.request_judgment(context,director.request_body(context,adapter.model))

func _story_suggestion(context: Dictionary, suggestion: Variant) -> void:
	pending_story = false
	if context.get("node") != session.story.node or context.get("slot_id") != slot_id or context.get("mode") != mode:
		return
	# Recheck eligibility at response time; never let delayed replies rewrite newer state.
	var allowed: Array = story.available()
	if allowed.is_empty():
		return
	var target := str(allowed[0])
	if suggestion is Dictionary and suggestion.get("node") in allowed and int(suggestion.get("request_id",-1)) == int(context.get("request_id",-2)):
		target = suggestion.node
	if story.advance(target):
		save_game()
		if hud.modal_kind == "journal":
			hud.show_journal()

func snapshot() -> Dictionary:
	var data := session.duplicate(true)
	data.position=[player.position.x,player.position.y]
	data.region=region
	data.inventory=[]
	for slot in inventory.slots:
		data.inventory.append({} if slot.is_empty() else {"id":slot.item.id,"quantity":slot.quantity})
	data.pickups=[]
	for pickup in pickups:
		data.pickups.append({"id":pickup.get_meta("item").id,"amount":pickup.get_meta("amount"),"region":pickup.get_meta("region"),"position":[pickup.position.x,pickup.position.y]})
	return data

func save_game() -> bool:
	if mode!="game" or saves.sandbox or slot_id==0:
		return false
	var data := snapshot()
	if saves.write_slot(slot_id,data):
		session.saved_at=data.saved_at
		dirty=false
		return true
	if is_instance_valid(hud):
		hud.notify("保存失败："+saves.last_error)
	return false

func _apply_settings() -> void:
	if is_instance_valid(hud):
		hud.apply_settings()
	for actor in characters.values():
		actor.reduce_flashes=settings.values.reduce_flashes

func _release_inputs() -> void:
	if is_instance_valid(adapter):
		adapter.cancel()
	pending_story = false
	player.touch_direction=Vector2.ZERO
	player.touch_run=false
	player.velocity=Vector2.ZERO
	player.input_locked=false
	player.investigating=false
	if is_instance_valid(hud):
		hud.release_touch()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if is_instance_valid(player):
			_release_inputs()
			player.input_locked = hud.modal_open() or ritual_timer>0
			if mode=="game":
				save_game()
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if mode=="game" and not save_game():
			return
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode if event.physical_keycode else event.keycode
		match key:
			KEY_ESCAPE:
				if hud.modal_open():
					hud.close_modal()
				else:
					hud.show_settings()
			KEY_E: interact()
			KEY_I,KEY_TAB:
				if mode!="menu" and ritual_timer<=0:
					hud.toggle()
			KEY_J:
				if mode!="menu":
					hud.show_journal()
			KEY_Q:
				if not hud.modal_open() or hud.opened:
					drop_selected()
		if key>=KEY_1 and key<=KEY_8:
			hud.selected=key-KEY_1
			if hud.opened:
				hud.show_inventory()
