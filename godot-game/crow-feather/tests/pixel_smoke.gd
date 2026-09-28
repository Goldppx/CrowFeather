extends SceneTree
## Run: Godot --headless --path <project> --script res://tests/pixel_smoke.gd
const InventoryModel = preload("res://scripts/items/Inventory.gd")
const ItemData = preload("res://scripts/items/InventoryItemData.gd")
var failures: Array[String] = []

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func(): push_error("Smoke test timed out"); quit(2))
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func key_press(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)

func _run() -> void:
	var item = ItemData.new()
	item.id = "test"
	item.slot_max = 5
	var bag = InventoryModel.new(2)
	check(bag.add_item(null, 1) == 0, "Null items must be rejected")
	check(bag.add_item(item, -2) == 0, "Negative addition must be rejected")
	check(bag.add_item(item, 7) == 7, "Stack overflow must use next slot")
	check(bag.get_slot(0).quantity == 5 and bag.get_slot(1).quantity == 2, "Stack split is incorrect")
	check(bag.add_item(item, 8) == 3, "Full inventory must report only the accepted amount")
	check(bag.get_total_quantity("test") == 10, "Full inventory lost or duplicated items")
	check(bag.remove_item(0, -1) == 0, "Negative removal must be rejected")
	check(bag.remove_item(0, 99) == 5 and bag.get_slot(0).is_empty(), "Removal must clear empty slots")
	item = ItemData.new()
	item.id = "key"
	item.stackable = false
	bag.clear()
	check(bag.add_item(item, 3) == 2, "Non-stackable items require individual slots")
	check(bag.get_slot(0).quantity == 1 and bag.get_slot(1).quantity == 1, "Non-stackable limit violated")

	var scene = load("res://scenes/PixelMain.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(3)
	check(scene.player is CharacterBody2D, "Player must use 2D physics")
	check(scene.actors.y_sort_enabled, "Depth sorting must be enabled")
	check(scene.pickups.size() == 4, "Initial pickups missing")
	key_press(KEY_E)
	await frames(2)
	check(scene.inventory.get_total_quantity("feather") == 3, "E must pick up nearby feathers")
	check(scene.pickups.size() == 3, "Collected pickup must leave the world")
	key_press(KEY_Q)
	await frames(2)
	check(scene.inventory.get_total_quantity("feather") == 2, "Q must drop exactly one item")
	key_press(KEY_E)
	await frames(2)
	check(scene.inventory.get_total_quantity("feather") == 3, "Dropped item must be collectible again")
	var start: Vector2 = scene.player.position
	Input.action_press("MOVE_RIGHT")
	await frames(30)
	Input.action_release("MOVE_RIGHT")
	await frames(10)
	check(scene.player.position.x > start.x + 20, "Movement action must move the player")
	check(scene.player.velocity.length() < 1, "Player must stop after release")
	Input.action_press("MOVE_RIGHT")
	Input.action_press("MOVE_BACKWARD")
	await frames(12)
	var ground_speed := Vector2(scene.player.velocity.x, scene.player.velocity.y / 0.72).length()
	check(absf(ground_speed - scene.player.walk_speed) < 0.5, "Diagonal movement must not be faster")
	Input.action_release("MOVE_BACKWARD")
	Input.action_press("RUN")
	await frames(12)
	check(absf(scene.player.velocity.x - scene.player.run_speed) < 0.5, "Shift sprint speed is incorrect")
	Input.action_release("RUN")
	Input.action_release("MOVE_RIGHT")
	await frames(10)
	key_press(KEY_I)
	await frames(2)
	check(scene.hud.opened and scene.player.input_locked, "Inventory must open and lock movement")
	start = scene.player.position
	Input.action_press("MOVE_RIGHT")
	await frames(15)
	Input.action_release("MOVE_RIGHT")
	check(scene.player.position.distance_to(start) < 1, "Movement leaked through the open inventory")
	key_press(KEY_ESCAPE)
	await frames(2)
	check(not scene.hud.opened and not scene.player.input_locked, "Escape must close inventory")
	# Walk into the pond from above: feet radius keeps us outside its top edge.
	scene.player.position = Vector2(680, 368)
	scene.player.velocity = Vector2.ZERO
	Input.action_press("MOVE_BACKWARD")
	await frames(45)
	Input.action_release("MOVE_BACKWARD")
	check(scene.player.position.y <= 380, "Pond collision did not block the player")
	# Partial pickup leaves the excess in the world.
	scene.inventory.clear()
	scene.inventory.add_item(scene.items.feather, 159)
	scene.player.position = Vector2(480, 340)
	var pickup = scene.spawn_pickup("feather", scene.player.position, 3)
	await frames(2)
	scene.collect_nearest()
	check(scene.inventory.get_total_quantity("feather") == 160, "Partial pickup should fill the last stack")
	check(is_instance_valid(pickup) and pickup.get_meta("amount") == 2, "Partial pickup lost remaining items")
	scene.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: inventory boundaries, pickup/drop/re-pickup, movement/stop, normalized diagonals, sprint, UI lock and pond collision")
	quit(0 if failures.is_empty() else 1)
