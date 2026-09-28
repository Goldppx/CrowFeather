extends Node2D
const Bank = preload("res://scripts/pixel/art_bank.gd")
var actor_id := "deer"
var state := "idle"
var visual: Sprite2D
var clock := 0.0
var current := -1
var direction := 0
var erase_material: ShaderMaterial
var erasing := false
var erase_progress := 0.0
var reduce_flashes := true
var foot_body: StaticBody2D

func _ready() -> void:
	visual = Sprite2D.new()
	add_child(visual)
	erase_material = ShaderMaterial.new()
	erase_material.shader = load("res://shaders/erase.gdshader")
	visual.material = erase_material
	_update_frame(0)
	foot_body = StaticBody2D.new()
	foot_body.collision_layer = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20,9)
	shape.shape = rect
	foot_body.add_child(shape)
	add_child(foot_body)

func face_toward(offset: Vector2) -> void:
	direction = (1 if offset.x>0 else 3) if absf(offset.x)>absf(offset.y) else (0 if offset.y>=0 else 2)
	current=-1

func set_state(value: String) -> void:
	state = value
	if is_instance_valid(foot_body):
		foot_body.collision_layer = 1 if value == "tomb" and visible else 0
	clock = 0
	current = -1
	erasing = false
	erase_progress = 0
	if is_instance_valid(visual):
		visual.modulate = Color.WHITE
		erase_material.set_shader_parameter("progress",0.0)
		erase_material.set_shader_parameter("actor_tint",Color(0.60,0.65,0.76,1.0) if value=="tomb" else Color(0.86,0.90,0.96,1.0))
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	var frame := 0
	match state:
		"talk": frame = 1 if int(clock*2.0)%2 == 0 else 0
		"walk": frame = [2,3,4,5][int(clock*7.0)%4]
		"death": frame = 6 if clock < 0.9 else 8
		"corpse": frame = 8
		"tomb": frame = 7
	_update_frame(frame)
	if erasing:
		erase_progress = minf(1.0,erase_progress + delta/2.8)
		erase_material.set_shader_parameter("progress",erase_progress)
	erase_material.set_shader_parameter("gentle",reduce_flashes)

func _update_frame(frame: int) -> void:
	var key := frame+direction*32
	if key == current:
		return
	var height := 20.0 if actor_id=="chicken" else 36.0
	if frame<6:
		Bank.apply_texture(visual,Bank.direction_texture(actor_id,direction,[0,3,1,0,2,0][frame]),height)
	else:
		Bank.apply(visual,actor_id,frame,36.0 if frame==7 else height)
	current = key

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.28))
	draw_circle(Vector2.ZERO,17 if state == "corpse" else 11,Color(0.015,0.02,0.03,0.4))
	draw_set_transform(Vector2.ZERO)

func erase() -> void:
	erasing = true
	erase_progress = 0
