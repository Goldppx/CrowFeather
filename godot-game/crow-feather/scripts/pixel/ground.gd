extends Node2D
const Art = preload("res://scripts/pixel/art.gd")
const WATER_RECT := Rect2(613, 385, 164, 76)
var actors: Node2D
var grass: Array[Vector2] = []
var stones: Array[Rect2] = []
var lights: Array[Vector2] = []
var scenery: Array[StaticBody2D] = []
var blockers: Array[StaticBody2D] = []
var ground_color := Color("20383b")
var menu_background: Texture2D
var cinematic_menu := true

func _build_ground() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1809
	for i in range(2600):
		grass.append(Vector2(rng.randi_range(105, 855), rng.randi_range(125, 585)))
	for row in range(7):
		for col in range(56):
			var x := 92 + col * 14 + (row % 2) * 7
			var y := 314 + row * 9
			stones.append(Rect2(x + rng.randi_range(0, 2), y + rng.randi_range(0, 1), rng.randi_range(9, 13), 6))
	for row in range(45):
		for col in range(6):
			stones.append(Rect2(442 + col * 13 + (row % 2) * 4, 169 + row * 9, 11, 7))

func _draw() -> void:
	if cinematic_menu and menu_background != null:
		draw_rect(Rect2(-200,-200,1600,1200),Color('0c1325'))
		draw_texture_rect(menu_background,Rect2(Vector2(480,335)-get_viewport_rect().size/2,get_viewport_rect().size),false)
		return
	draw_rect(Rect2(0, 0, 1000, 720), Color("15282e"))
	draw_rect(Rect2(114, 138, 740, 447), ground_color)
	for p in grass:
		var tint := Color("294247") if int(p.x) % 3 == 0 else Color("1a3036")
		draw_rect(Rect2(p, Vector2(2, 1)), tint)
		if int(p.x) % 7 == 0:
			draw_line(p, p + Vector2(-1, -3), Color("36524e"))
	draw_rect(Rect2(100, 310, 760, 74), Color("293a3c"))
	draw_rect(Rect2(438, 150, 89, 444), Color("293a3c"))
	for stone in stones:
		var c := Color("415253") if int(stone.position.x) % 3 == 0 else Color("36484b")
		draw_rect(stone, Color("182d33"))
		draw_rect(Rect2(stone.position, stone.size - Vector2(0, 1)), c)
	# Raised cemetery terraces: top plane, front edge, and narrow stone steps.
	draw_rect(Rect2(224, 204, 169, 80), Color("10252d"))
	draw_rect(Rect2(224, 199, 169, 77), Color("34494b"))
	for i in range(8):
		draw_line(Vector2(224 + i * 23, 200), Vector2(224 + i * 23, 276), Color("263d40"))
	for i in range(3):
		draw_rect(Rect2(298, 276 + i * 4, 30, 3), Color("56615a"))
	# Old boundary wall and its vertical front face.
	for i in range(35):
		var x := 117 + i * 21
		if x > 430 and x < 529:
			continue
		draw_rect(Rect2(x, 164, 20, 27), Color("172a32"))
		draw_rect(Rect2(x, 159, 20, 6), Color("526362"))
		draw_rect(Rect2(x + 1, 169, 18, 5), Color("30454b"))
		draw_line(Vector2(x, 181), Vector2(x + 20, 181), Color("31484c"))
	for x in [418, 536]:
		draw_rect(Rect2(x, 129, 15, 67), Color("172a32"))
		draw_rect(Rect2(x - 3, 126, 21, 7), Color("69726a"))
		draw_rect(Rect2(x + 3, 137, 9, 52), Color("344b4e"))
	# Pond rim. Its animated surface is a shader-driven Polygon2D.
	draw_rect(WATER_RECT.grow(5), Color("10252b"))
	draw_rect(Rect2(608, 382, 174, 3), Color("53605a"))
	for light in lights:
		for i in range(5, 0, -1):
			draw_set_transform(light, 0, Vector2(1, 0.48))
			draw_circle(Vector2.ZERO, i * 12, Color(0.85, 0.59, 0.24, 0.018))
		draw_set_transform(Vector2.ZERO)
	# Broken flagstones and reeds around the water.
	for i in range(14):
		var x := 615 + i * 12
		draw_rect(Rect2(x, 466 + (i % 3), 8, 2), Color("3d5554"))

func _prop(frame: int, pos: Vector2, cell_size: float, collision_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.name = "Prop_%d_%d" % [frame, actors.get_child_count()]
	actors.add_child(body)
	scenery.append(body)
	var shadow := Polygon2D.new()
	shadow.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-7, -4), Vector2(9, -3), Vector2(15, 2), Vector2(4, 5), Vector2(-8, 3)])
	shadow.color = Color(0.03, 0.055, 0.07, 0.5)
	body.add_child(shadow)
	body.add_child(Art.sprite(frame, cell_size))
	if collision_size != Vector2.ZERO:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = collision_size
		collision.shape = shape
		collision.position.y = -2
		body.add_child(collision)
	if frame == 8:
		lights.append(pos)
		var light := PointLight2D.new()
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(1, 1, 1, 0.65), Color(1, 1, 1, 0)])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1, 0.5)
		light.texture = texture
		light.color = Color("ffc77a")
		light.energy = 0.55
		light.position.y = -cell_size * 0.55
		body.add_child(light)

func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.position = rect.get_center()
	body.add_child(collision)
	add_child(body)
	blockers.append(body)

func _build_props() -> void:
	for pos in [Vector2(271, 239), Vector2(341, 247), Vector2(274, 274), Vector2(360, 269), Vector2(596, 260)]:
		_prop(9, pos, 51, Vector2(18, 10))
	for pos in [Vector2(216, 361), Vector2(404, 302), Vector2(550, 394), Vector2(716, 309)]:
		_prop(8, pos, 91, Vector2(10, 9))
	for pos in [Vector2(173, 270), Vector2(776, 235), Vector2(233, 490), Vector2(803, 490), Vector2(577, 171)]:
		_prop(11, pos, 140, Vector2(19, 10))
	for pos in [Vector2(609, 326), Vector2(634, 307), Vector2(369, 445)]:
		_prop(10, pos, 43, Vector2(23, 17))
	for pos in [Vector2(195, 298), Vector2(237, 208), Vector2(390, 255), Vector2(668, 210), Vector2(748, 399), Vector2(329, 471), Vector2(594, 468), Vector2(535, 501), Vector2(724, 475)]:
		_prop(15, pos, 47, Vector2.ZERO)
	_wall(Rect2(95, 120, 770, 16))
	_wall(Rect2(95, 582, 770, 16))
	_wall(Rect2(90, 120, 16, 478))
	_wall(Rect2(854, 120, 16, 478))
	_wall(Rect2(114, 164, 316, 27))
	_wall(Rect2(530, 164, 324, 27))
	_wall(WATER_RECT)

func _build_water() -> void:
	var water := Polygon2D.new()
	water.name = "Water"
	water.position = WATER_RECT.position
	water.polygon = PackedVector2Array([Vector2.ZERO, Vector2(164, 0), Vector2(164, 76), Vector2(0, 76)])
	# A tiny white texture gives Polygon2D normalized UV coordinates.
	var image := Image.create(164, 76, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	water.texture = ImageTexture.create_from_image(image)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/pixel_water.gdshader")
	water.material = material
	add_child(water)
	move_child(water, 0)
