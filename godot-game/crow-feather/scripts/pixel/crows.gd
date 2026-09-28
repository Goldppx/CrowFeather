extends Node2D
const Bank = preload("res://scripts/pixel/art_bank.gd")
var world
var birds: Array[Sprite2D] = []
var elapsed := 0.0
var target := Vector2(600,260)

func _ready() -> void:
	z_index = 20
	for i in range(16):
		var bird := Sprite2D.new()
		bird.texture = Bank.texture("crow",0)
		bird.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/crow.gdshader")
		bird.material = mat
		add_child(bird)
		birds.append(bird)

func _process(delta: float) -> void:
	var reduced: bool = world.settings.values.reduce_motion
	elapsed += 0.0 if reduced else delta
	var count := 4 + mini(12,int(world.session.get("story",{}).get("distortion",0)))
	for i in range(birds.size()):
		var bird := birds[i]
		bird.visible = i < count
		if not bird.visible:
			continue
		var t := elapsed * (0.28 + i*0.007) + i*1.17
		var center: Vector2 = target + Vector2(0,-88)
		bird.position = center + Vector2(cos(t)*float(56+i*4),sin(t)*float(18+i%3*6))
		bird.texture = Bank.texture("crow",int(elapsed*7.0+i)%8)
		bird.scale = Vector2.ONE * 28.0 / bird.texture.get_width()
		bird.flip_h = sin(t)>0
		var warm := 0.0
		for lamp in world.lights:
			warm = maxf(warm,1.0-clampf(bird.position.distance_to(lamp+Vector2(0,-55))/75.0,0.0,1.0))
		bird.material.set_shader_parameter("warm_light",warm)
		bird.material.set_shader_parameter("gentle",world.settings.values.reduce_flashes)
