extends SceneTree
const Saves = preload("res://scripts/pixel/save_store.gd")
const Story = preload("res://scripts/pixel/story.gd")
const Director = preload("res://scripts/pixel/director.gd")
const InventoryModel = preload("res://scripts/items/Inventory.gd")
const ItemData = preload("res://scripts/items/InventoryItemData.gd")
var failures: Array[String]=[]
var world
var test_dir: String

func _initialize() -> void:
	create_timer(50).timeout.connect(func(): push_error("Integration timeout"); quit(2))
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func run() -> void:
	var store := Saves.new()
	test_dir="user://test_saves_"+str(Time.get_ticks_usec())
	store.directory=test_dir
	var data := store.fresh()
	check(store.write_slot(1,data),"initial atomic save")
	data.region="pig"
	check(store.write_slot(1,data),"replace existing save atomically")
	check(store.read_slot(1).region=="pig","saved region roundtrip")
	var f:=FileAccess.open(store.path_for(1),FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	check(store.read_slot(1).region=="deer" and store.recovered,"corrupt primary recovers valid backup")
	var invalid:=store.fresh()
	invalid.story.erased="bad"
	check(not store.validate(invalid),"malformed counters rejected")
	invalid=store.fresh()
	invalid.version=99
	check(not store.validate(invalid),"unknown schema rejected")
	check(not store.write_slot(0,data),"invalid slot rejected")
	store.sandbox=true
	var before_hash:=FileAccess.get_sha256(store.path_for(1))
	check(not store.write_slot(1,data),"sandbox writer refuses save")
	check(before_hash==FileAccess.get_sha256(store.path_for(1)),"sandbox preserves exact file bytes")
	var item=ItemData.new()
	item.id="sample"
	item.slot_max=5
	var bag=InventoryModel.new(2)
	check(bag.add_item(null,3)==0 and bag.add_item(item,-1)==0,"inventory rejects invalid adds")
	check(bag.add_item(item,12)==10,"stack overflow bounded")
	check(bag.remove_item(0,2)==2,"remove item quantity")
	var story:=Story.new()
	var state: Dictionary=store.fresh().story
	state.flags.mail_route=true
	story.bind(state)
	check(story.advance("deer_mourning"),"arrival advances")
	check(not story.advance("self"),"cannot skip authored graph")
	check(story.judge("deer",true),"verdict applies")
	check(not story.judge("deer",false) and state.erased==1,"verdict idempotency")
	check(story.available()==["empty_garden"],"erase opens correct local branch")
	check(story.advance("empty_garden") and story.advance("crossroads"),"local branch converges")
	var director:=Director.new()
	check(director.choose(story,[],{"node":"illegal"})=="letters","invalid agent output falls back")
	check(director.choose(story,[],"malformed JSON")=="letters","malformed agent output falls back")
	story.judge("horse",true)
	check(story.available()==["silence"],"horse erased changes downstream edge")
	check(story.advance("silence") and story.advance("bell_return"),"alternate branch converges")
	for id in ["pig","sheep","chicken"]:
		story.judge(id,true)
	check(story.advance("self") and story.ending()=="因果坍塌","erase ending reachable")
	var accepted: Dictionary=store.fresh().story
	story.bind(accepted)
	for id in Story.ACTORS: story.judge(id,false)
	check(story.ending()=="顺应宿命","accept ending reachable")
	world=load("res://scenes/PixelMain.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	world.saves.directory=test_dir+"/world"
	await frames(3)
	check(world.mode=="menu","boot opens walkable cemetery")
	check(world.graves.size()==3,"three independent grave slots")
	world.open_slot(1)
	await frames(3)
	check(world.mode=="game" and world.pickups.size()==15,"new world resources")
	world.player.position=Vector2(505,385)
	await frames(3)
	world.collect_nearest()
	check(world.inventory.get_total_quantity("feather")==3,"pickup works")
	world.drop_selected()
	await frames(3)
	check(world.inventory.get_total_quantity("feather")==2,"drop works")
	world.collect_nearest()
	check(world.inventory.get_total_quantity("feather")==3,"dropped item recovered")
	world.player.position=Vector2(480,355)
	var start: Vector2=world.player.position
	Input.action_press("MOVE_RIGHT")
	await frames(30)
	Input.action_release("MOVE_RIGHT")
	await frames(10)
	check(world.player.position.x>start.x+20,"walking moves player")
	check(world.player.velocity.length()<1,"release stops")
	world.hud.show_inventory()
	start=world.player.position
	Input.action_press("MOVE_RIGHT")
	await frames(12)
	Input.action_release("MOVE_RIGHT")
	check(world.player.position.distance_to(start)<0.1,"modal locks movement immediately")
	world.hud.close_modal()
	world.player.position=Vector2(680,368)
	Input.action_press("MOVE_BACKWARD")
	await frames(40)
	Input.action_release("MOVE_BACKWARD")
	check(world.player.position.y<=380,"pond collisions")
	world.judge("deer",true)
	check(world.saves.read_slot(1).story.decisions.deer=="erased","ritual decision persists immediately")
	world.ritual_timer=0
	world.travel("pig")
	world.player.position=Vector2(470,380)
	world.save_game()
	world.enter_menu()
	world.open_slot(2)
	check(world.session.story.erased==0 and world.inventory.get_total_quantity("feather")==0,"second slot isolated")
	world.enter_menu()
	world.open_slot(1)
	check(world.region=="pig" and world.inventory.get_total_quantity("feather")==3 and world.session.story.erased==1,"continue restores region inventory decisions")
	check(world.player.position.distance_to(Vector2(470,380))<1,"position restored")
	var live_hash:=FileAccess.get_sha256(world.saves.path_for(1))
	world.adapter.enabled=true
	world.adapter.endpoint=""
	var checkpoint: String=world.session.story.node
	world.request_story_step()
	check(not world.pending_story and world.session.story.node!=checkpoint,"unconfigured adapter immediately falls back")
	world.adapter.enabled=false
	world.enter_menu()
	world.click_dev()
	world.click_dev()
	world.click_dev()
	check(world.mode=="dev" and world.saves.sandbox,"DEV sequence enters sandbox")
	live_hash=FileAccess.get_sha256(world.saves.path_for(1))
	world.judge("sheep",true)
	world.save_game()
	check(live_hash==FileAccess.get_sha256(world.saves.path_for(1)),"test room cannot overwrite active save")
	world.hud.mobile_mode=true
	world.hud.close_modal()
	world.hud.update_stick(world.hud.stick_center()+Vector2(48,0))
	await frames(5)
	check(world.player.touch_direction.x>0.5,"mobile joystick analog direction")
	world.hud.show_settings()
	check(world.player.touch_direction==Vector2.ZERO and not world.player.touch_run,"modal releases touch movement")
	world.settings.set_value("reduce_motion",true,false)
	var clock: float=world.fog_clock
	await frames(4)
	check(world.fog_clock==clock,"reduced motion freezes procedural fog")
	world.settings.set_value("bgm",0.0,false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("BGM")),"BGM mute actually affects bus")
	world.settings.set_value("sfx",0.0,false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"SFX mute actually affects bus")
	world.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	if failures.is_empty():
		print("PASS: persistence, corrupt backup, slot isolation, sandbox, graph convergence, agent fallback, endings, inventory, movement, collisions, mobile input and accessibility")
	else:
		print("FAILED: ",failures)
	quit(0 if failures.is_empty() else 1)
