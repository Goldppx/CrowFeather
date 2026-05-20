extends CharacterBody3D
class_name PlayerController

@onready var state_machine: Node = %StateMachine
@onready var camera_pivot: Node3D = %CameraPivot
@onready var player_camera: Camera3D = %Camera3D

# Input
var move_input := Vector2.ZERO
var jump_pressed := false
var run_pressed := false

# Movement
var speed := 6.0
var run_multiplier := 2.0
var accel := 40.0
var decel := 18.0
var jump_force := 8.0

# Gravity
const GRAVITY := -12.0
const MAX_FALL_SPEED := -50.0

# ── 背包系统 ──
var inventory: Inventory
@onready var inventory_ui: InventroyUI = %InventroyUI

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

func process_input():
	move_input = Vector2(
		Input.get_action_strength("MOVE_RIGHT") - Input.get_action_strength("MOVE_LEFT"),
		Input.get_action_strength("MOVE_BACKWARD") - Input.get_action_strength("MOVE_FORWARD")
	)

	jump_pressed = Input.is_action_just_pressed("JUMP")
	run_pressed = Input.is_action_pressed("RUN")

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
