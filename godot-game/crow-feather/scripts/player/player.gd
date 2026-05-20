extends CharacterBody3D
class_name PlayerController

@onready var state_machine: Node = %StateMachine
@onready var camera_pivot: Node3D = %CameraPivot
@onready var player_camera: Camera3D = %Camera3D

# Input
var move_input := Vector2.ZERO
var jump_pressed := false
var run_pressed := false
var crouch_pressed := false
var use_pressed := false

# Movement
var speed := 6.0
var run_multiplier := 2.0
var crouch_multiplier := 0.5
var accel := 40.0
var decel := 18.0
var jump_force := 8.0
var interact_distance := 5

# Gravity
const GRAVITY := -12.0
const MAX_FALL_SPEED := -50.0

# ── 背包系统 ──
var inventory: Inventory
@onready var inventory_ui: InventroyUI = %InventroyUI
@onready var interact_label: Label = %InteractLabel

func _ready():
	state_machine.initialize(self)
	
	# 初始化背包
	inventory = Inventory.new(5)
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory_ui.refresh_from(inventory)
	
	# 测试：填 3 个物品
	_test_fill_inventory()

func _process(delta):
	state_machine._process(delta)
	if Input.is_action_just_pressed("INVENTORY"):
		print("Toggled Invertory")
		inventory_ui.visible = not inventory_ui.visible

func _physics_process(delta):
	process_input()
	state_machine._physics_process(delta)
	move_and_slide()

	# 交互检测
	_interact_raycast()
	if use_pressed:
		try_interact()

func process_input():
	move_input = Vector2(
		Input.get_action_strength("MOVE_RIGHT") - Input.get_action_strength("MOVE_LEFT"),
		Input.get_action_strength("MOVE_BACKWARD") - Input.get_action_strength("MOVE_FORWARD")
	)

	jump_pressed = Input.is_action_just_pressed("JUMP")
	run_pressed = Input.is_action_pressed("RUN")
	crouch_pressed = Input.is_action_pressed("CROUCH")
	use_pressed = Input.is_action_just_pressed("USE")

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = max(velocity.y, MAX_FALL_SPEED)
	else:
		velocity.y = 0.0

func jump():
	if is_on_floor():
		velocity.y = jump_force

func get_input_direction() -> Vector3:
	var yaw = camera_pivot.global_transform.basis.get_euler().y
	var dir = Vector3(move_input.x, 0, move_input.y)
	return dir.rotated(Vector3.UP, yaw).normalized()

func move_horizontally(delta: float, speed_scale: float = 1.0):
	var direction = get_input_direction()
	var target_speed = speed * speed_scale
	var desired_velocity = direction * target_speed

	var horizontal_velocity = velocity
	horizontal_velocity.y = 0.0

	var acceleration = accel if direction.length() > 0 else decel
	horizontal_velocity = horizontal_velocity.lerp(desired_velocity, acceleration * delta)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

func stop_horizontal_movement(delta: float):
	velocity.x = move_toward(velocity.x, 0.0, decel * delta)
	velocity.z = move_toward(velocity.z, 0.0, decel * delta)

# ── 背包接口 ──

func pickup_item(item_data: InventoryItemData, amount: int = 1) -> bool:
	var added = inventory.add_item(item_data, amount)
	return added > 0

func _on_inventory_changed(index: int):
	inventory_ui.refresh_slot(index, inventory)

# ── 交互系统 ──

var _focused_item: PickupItem = null

func _interact_raycast():
	var camera = player_camera
	var space_state = get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * interact_distance

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	var new_focus: PickupItem = null
	if result and result.collider is PickupItem:
		new_focus = result.collider

	if new_focus != _focused_item:
		_focused_item = new_focus
		_update_interact_prompt()

func _update_interact_prompt():
	if _focused_item:
		interact_label.text = _focused_item.get_interact_text()
		interact_label.show()
	else:
		interact_label.hide()

func try_interact():
	if not _focused_item:
		return

	var item = _focused_item
	var added = pickup_item(item.item_data, 1)
	if added:
		item.queue_free()
		_focused_item = null
		_update_interact_prompt()
		print("拾取了: %s" % item.item_data.item_name)

func _test_fill_inventory():
	var test_item = InventoryItemData.new()
	test_item.id = "test_item"
	test_item.item_name = "Test"
	test_item.description = "测试物品"
	test_item.icon = preload("res://icon.svg")
	test_item.stackable = true
	test_item.max_stack = 99
	test_item.slot_max = 99
	
	var test_item2 = InventoryItemData.new()
	test_item2.id = "test_item2"
	test_item2.item_name = "Test"
	test_item2.description = "测试物品二"
	test_item2.icon = preload("res://icon.svg")
	test_item2.stackable = true
	test_item2.max_stack = 99
	test_item2.slot_max = 99
	
	pickup_item(test_item, 5)
	pickup_item(test_item2, 1)
	pickup_item(test_item, 3)
