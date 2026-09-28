extends CharacterBody2D

const Art = preload("res://scripts/pixel/art.gd")
@export var walk_speed := 88.0
@export var run_speed := 132.0
@export var acceleration := 720.0
var input_locked := false
var facing := Vector2.DOWN
var animation_time := 0.0
var visual: Sprite2D
var current_frame := -1

func _ready() -> void:
	name = "Player"
	motion_mode = MOTION_MODE_FLOATING
	visual = Art.sprite(0)
	visual.name = "Sprite"
	add_child(visual)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 10, Color(0.025, 0.035, 0.05, 0.5))
	draw_set_transform(Vector2.ZERO)

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if not input_locked:
		direction = Input.get_vector("MOVE_LEFT", "MOVE_RIGHT", "MOVE_FORWARD", "MOVE_BACKWARD")
	if direction.length_squared() > 0.01:
		facing = direction
	var speed := run_speed if Input.is_action_pressed("RUN") else walk_speed
	# Ground depth is compressed; diagonal input is normalized before projection.
	var projected := Vector2(direction.x, direction.y * 0.72)
	velocity = velocity.move_toward(projected * speed, acceleration * delta)
	move_and_slide()
	animation_time += delta * (12.0 if speed == run_speed else 8.0)
	var moving := velocity.length() > 4.0
	var step := int(animation_time) % 2
	var frame := 0
	if absf(facing.x) > absf(facing.y):
		frame = 5 + step if moving else 4
		visual.flip_h = facing.x < 0
	elif facing.y < 0:
		frame = 7 if moving and step == 1 else 3
		visual.flip_h = false
	else:
		frame = 1 + step if moving else 0
		visual.flip_h = false
	if current_frame != frame:
		visual.texture = Art.texture(frame)
		current_frame = frame
