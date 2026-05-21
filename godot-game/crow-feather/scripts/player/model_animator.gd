extends Node3D
class_name ModelAnimator

## 不用骨骼动画，纯程序化让静态模型"活起来"
## 适用于 A-pose / 自然垂手姿态的模型

@export var model: Node3D                     # 角色模型（A-pose）
@export var idle_breath_amp: float = 0.003    # 呼吸幅度
@export var walk_bob_amp: float = 0.06        # 走路上下幅度
@export var walk_sway_amp: float = 0.04       # 走路左右摇摆幅度
@export var walk_freq: float = 8.0            # 走路频率
@export var run_bob_amp: float = 0.10
@export var run_freq: float = 12.0
@export var tilt_on_turn: float = 0.06        # 转向倾斜幅度

var idle_breath_time: float = 0.0
var motion_time: float = 0.0
var current_speed: float = 0.0
var last_velocity: Vector3 = Vector3.ZERO
var target_tilt: float = 0.0
var current_tilt: float = 0.0

func _ready():
	if not model:
		# 尝试找第一个 MeshInstance3D 子节点
		for child in get_children():
			if child is MeshInstance3D:
				model = child
				break

func _process(delta):
	if not model:
		return

	# 获取玩家速度
	var player = _get_player()
	if not player:
		return

	var vel = player.velocity
	var horizontal_speed = Vector3(vel.x, 0, vel.z).length()
	current_speed = lerp(current_speed, horizontal_speed, delta * 10.0)

	# 获取当前状态名
	var state_name = ""
	if player.state_machine and player.state_machine.current_state:
		state_name = player.state_machine.current_state.name

	# ── 根据状态应用效果 ──
	match state_name:
		"Idle":
			_update_idle(delta)
		"Move":
			_update_move(delta, horizontal_speed)
		"Jump":
			_update_jump(delta, vel.y)
		"Fall":
			_update_fall(delta, vel.y)

	# ── 转向倾斜（平滑） ──
	_track_turn(vel, delta)

func _update_idle(delta):
	idle_breath_time += delta * 2.0
	motion_time = lerp(motion_time, 0.0, delta * 5.0)

	# 呼吸：微小的 Y 轴缩放 + 上下浮动
	var breath = 1.0 + sin(idle_breath_time) * idle_breath_amp
	model.scale.y = breath

	# 归位
	model.position.y = lerp(model.position.y, 0.0, delta * 5.0)
	model.rotation.z = lerp(model.rotation.z, 0.0, delta * 5.0)
	model.rotation.x = lerp(model.rotation.x, 0.0, delta * 5.0)

func _update_move(delta, speed):
	motion_time += delta * walk_freq * clamp(speed / 3.0, 0.5, 1.5)

	# 上下弹跳（走路感）
	var bob = sin(motion_time) * walk_bob_amp
	model.position.y = bob

	# 左右摇摆（手臂那侧的模型整体微晃）
	var sway = sin(motion_time * 0.5) * walk_sway_amp
	model.rotation.z = sway

	# 略微前倾（有速度感）
	model.rotation.x = lerp(model.rotation.x, -0.05, delta * 5.0)

	# 还原呼吸缩放
	model.scale.y = 1.0

func _update_jump(delta, vel_y):
	# 起跳时身体伸展，下落时收紧
	var squash = clamp(1.0 + vel_y * 0.01, 0.9, 1.15)
	model.scale.y = squash
	model.scale.x = 2.0 - squash
	model.scale.z = 2.0 - squash

	# 手臂上举感：整体微微后仰
	model.rotation.x = lerp(model.rotation.x, -0.1, delta * 8.0)

func _update_fall(delta, vel_y):
	# 下落时身体前倾（找平衡感）
	var tilt = clamp(vel_y * -0.01, 0.0, 0.15)
	model.rotation.x = lerp(model.rotation.x, tilt, delta * 5.0)

	# 下落时略微收紧
	model.scale.y = lerp(model.scale.y, 0.97, delta * 3.0)

func _track_turn(vel: Vector3, delta: float):
	# 检测横向速度变化来判断转向
	var horizontal = Vector3(vel.x, 0, vel.z)
	var dir_change = horizontal - Vector3(last_velocity.x, 0, last_velocity.z)
	var lateral = dir_change.length()

	# 横向移动越大→倾斜越大
	target_tilt = clamp(lateral * 0.3, -tilt_on_turn, tilt_on_turn)
	# 根据左右方向决定正负（简化版：根据横向速度方向）
	var cross = Vector3.UP.cross(horizontal.normalized())
	target_tilt *= sign(cross.y) if cross.y != 0 else 0

	current_tilt = lerp(current_tilt, target_tilt, delta * 8.0)
	# 转向倾斜应用在 Z 轴旋转上（叠加在走路 sway 之上）
	# 注意：这里我们不做叠加，因为 _update_move 也在控制 rotation.z
	# 如果你的模型有独立的 root，可以分开控制

	last_velocity = vel

func _get_player():
	var parent = get_parent()
	while parent:
		if parent is PlayerController:
			return parent
		parent = parent.get_parent()
	return null

## 用于切换不同姿态的模型（如果你有多个静态模型）
func switch_model(new_model: Node3D):
	if model:
		model.visible = false
	model = new_model
	if model:
		model.visible = true
