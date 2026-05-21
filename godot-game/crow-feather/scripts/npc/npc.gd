extends CharacterBody3D
class_name NPC

## NPC 基类 — 没有动画，纯静态模型
##
## 用法：
##   1. 把 AI 生成的 A-pose 模型拖到 scene 里作为 NpcModel 的子节点
##   2. 在 Godot 编辑器里把模型节点拖到 @export var model 上
##   3. 调整 collision_height 匹配模型高度
##
## 默认身高 1.7m，碰撞体为胶囊体

@export var model: Node3D                    # 角色模型（A-pose 静态）
@export var collision_height: float = 1.7    # 碰撞体高度
@export var collision_radius: float = 0.4    # 碰撞体半径

# 程序化微动参数（让静态模型看起来不死板）
@export var breath_enabled: bool = true
@export var breath_amplitude: float = 0.002  # 呼吸幅度

var _breath_time: float = 0.0
var _initial_model_y: float = 0.0

func _ready():
	_setup_collision()
	
	if model:
		_initial_model_y = model.position.y
	else:
		# 尝试自动找第一个 MeshInstance3D 子节点
		for child in get_children():
			if child is MeshInstance3D:
				model = child
				_initial_model_y = model.position.y
				break

func _process(delta):
	if not model:
		return
	
	if breath_enabled:
		_breath_time += delta * 1.5
		# 极轻微的呼吸起伏
		var breath = 1.0 + sin(_breath_time) * breath_amplitude
		model.scale.y = breath

func _setup_collision():
	# 清除旧碰撞
	for child in get_children():
		if child is CollisionShape3D:
			child.queue_free()
	
	# 创建胶囊碰撞体
	var capsule = CapsuleShape3D.new()
	capsule.height = collision_height
	capsule.radius = collision_radius
	
	var collision = CollisionShape3D.new()
	collision.shape = capsule
	add_child(collision)
	collision.owner = self

## 设置模型（运行时切换）
func set_model(new_model: Node3D):
	if model:
		model.visible = false
		remove_child(model)
	
	model = new_model
	if model:
		model.visible = true
		add_child(model)
		model.owner = self
		_initial_model_y = model.position.y

## 设置朝向
func look_towards(target: Vector3):
	var dir = (target - global_position)
	dir.y = 0
	if dir.length_squared() > 0.001:
		look_at(global_position + dir.normalized(), Vector3.UP)
