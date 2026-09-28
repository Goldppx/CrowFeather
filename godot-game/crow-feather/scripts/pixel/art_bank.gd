extends RefCounted
## The original sheets remain lossless. Atlas regions use measured row boundaries.
const ROWS := {"deer": [0.0,0.35,0.70], "horse": [0.0,0.31,0.62], "pig": [0.0,0.32,0.64], "sheep": [0.0,0.33,0.64], "chicken": [0.0,0.32,0.59]}
static var cache: Dictionary = {}
static var sheets: Dictionary = {}

static func texture(id: String, frame: int) -> Texture2D:
	var key := id + str(frame)
	if cache.has(key):
		return cache[key]
	var sheet: Texture2D
	if sheets.has(id):
		sheet = sheets[id]
	else:
		sheet = load("res://art/characters/%s.png" % id)
		sheets[id] = sheet
	if sheet == null:
		return null
	var size := sheet.get_size()
	var rect: Rect2
	if id == "player":
		var cell := size / 4.0
		rect = Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
	elif id == "crow":
		var cell := size / Vector2(4,2)
		rect = Rect2(Vector2(frame % 4, frame / 4) * cell, cell)
	else:
		var rows: Array = ROWS[id]
		if frame == 8:
			rect = Rect2(0,size.y * rows[2],size.x,size.y * (1.0-rows[2]))
		else:
			var row := frame / 4
			rect = Rect2(float(frame % 4)*size.x/4.0,size.y*rows[row],size.x/4.0,size.y*(rows[row+1]-rows[row]))
	# Trim transparent padding without modifying the generated artwork.
	var crop := Rect2i(rect)
	var used := sheet.get_image().get_region(crop).get_used_rect()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(crop.position + used.position, used.size)
	atlas.filter_clip = true
	cache[key] = atlas
	return atlas

static func apply(sprite: Sprite2D, id: String, frame: int, height := 62.0) -> void:
	sprite.texture = texture(id, frame)
	if sprite.texture == null:
		return
	var base := texture(id, 0)
	var factor := height / base.get_height()
	if frame == 8 and id not in ["player","crow"]:
		factor = height * 1.35 / sprite.texture.get_width()
	sprite.centered = false
	sprite.offset = Vector2(-sprite.texture.get_width()/2.0,-sprite.texture.get_height())
	sprite.scale = Vector2.ONE * factor
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
