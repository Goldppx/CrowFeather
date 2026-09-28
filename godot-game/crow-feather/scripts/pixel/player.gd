extends CharacterBody2D
const Bank = preload("res://scripts/pixel/art_bank.gd")
@export var walk_speed := 88.0
@export var run_speed := 132.0
@export var acceleration := 720.0
var input_locked := false
var facing := Vector2.DOWN
var animation_time := 0.0
var visual: Sprite2D
var current_frame := -1
var touch_direction := Vector2.ZERO
var touch_run := false
var investigating := false

func _ready() -> void:
	name = "Player"
	motion_mode = MOTION_MODE_FLOATING
	visual = Sprite2D.new()
	visual.name = "Sprite"
	add_child(visual)
	Bank.apply(visual, "player", 12, 62.0)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	add_child(collision)

func _draw() -> void:
	draw_set_transform(Vector2(0,1),0,Vector2(1,0.32))
	draw_circle(Vector2.ZERO, 12, Color(0.01,0.015,0.025,0.48))
	draw_set_transform(Vector2.ZERO)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if not input_locked:
		direction = Input.get_vector("MOVE_LEFT","MOVE_RIGHT","MOVE_FORWARD","MOVE_BACKWARD")
		if touch_direction.length() > 0.12:
			direction = touch_direction
	var running := Input.is_action_pressed("RUN") or touch_run
	var speed := run_speed if running else walk_speed
	if direction.length() > 0.05:
		facing = direction
	var projected := Vector2(direction.x,direction.y*0.72)
	velocity = Vector2.ZERO if input_locked else velocity.move_toward(projected*speed,acceleration*delta)
	var before := position
	move_and_slide()
	# Advance by actual travelled distance: a wall or a pause cannot trigger moonwalking.
	var distance := position.distance_to(before)
	var moving := distance > 0.04
	if moving:
		animation_time += distance / 46.0 * 4.0
	else:
		animation_time = 0
	var row := 0
	if absf(facing.x) > absf(facing.y):
		row = 2
	elif facing.y < 0:
		row = 1
	visual.flip_h = row == 2 and facing.x < 0
	var frame := row*4 + int(animation_time)%4 if moving else 12+row
	if investigating:
		frame = 15
		visual.flip_h = false
	if frame != current_frame:
		Bank.apply(visual,"player",frame,62.0)
		current_frame = frame
