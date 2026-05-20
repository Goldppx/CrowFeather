extends Node3D
class_name CameraController

@export var sensitivity := 0.005
@export var min_pitch := deg_to_rad(-80)
@export var max_pitch := deg_to_rad(80)

var yaw := 0.0
var pitch := 0.0

@export var normal_height: float = 1.7      # 站立时高度                                                                                                                                                   
@export var crouch_height: float = 1.0      # 蹲下时高度                                                                                                                                                   
@export var height_speed: float = 10.0      # 过渡速度

@onready var camera: Camera3D = %Camera3D
@onready var player: PlayerController = get_parent()
@onready var state: Node = %StateMachine

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative
		yaw -= mouse_delta.x * sensitivity
		pitch -= mouse_delta.y * sensitivity
		pitch = clamp(pitch, min_pitch, max_pitch)

		rotation.y = yaw
		camera.rotation.x = pitch

func _process(delta: float) -> void:
	var target_fov = 90.0 if (player.run_pressed and ) else 75.0
	camera.fov = lerp(camera.fov, target_fov, height_speed * delta)
	var target_height = crouch_height if player.crouch_pressed else normal_height
	position.y = lerp(position.y, target_height, height_speed * delta)
