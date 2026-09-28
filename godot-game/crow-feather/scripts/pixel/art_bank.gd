extends RefCounted
## The original sheets remain lossless. Atlas regions use measured row boundaries.
const ROWS := {"deer": [0.0,0.35,0.70], "horse": [0.0,0.31,0.62], "pig": [0.0,0.32,0.64], "sheep": [0.0,0.33,0.64], "chicken": [0.0,0.32,0.59]}
static var cache: Dictionary = {}
static var sheets: Dictionary = {}
static var image_cache: Dictionary = {}
static var band_cache: Dictionary = {}

static func legacy_texture(id: String, frame: int) -> Texture2D:
	var key := "legacy:"+id + str(frame)
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

## Every generated frame is rasterized to a tiny pixel grid before display.
static func direction_texture(id: String, direction: int, pose: int) -> Texture2D:
	var key := "tiny:%s:%d:%d" % [id,direction,pose]
	if cache.has(key): return cache[key]
	var sheet_key := id+"-v2"
	if not sheets.has(sheet_key): sheets[sheet_key] = load("res://art/characters/%s-v2.png" % id)
	var sheet: Texture2D = sheets[sheet_key]
	if sheet == null: return legacy_texture(id,0)
	if not image_cache.has(id):
		image_cache[id] = sheet.get_image()
		band_cache[id] = find_bands(image_cache[id])
	var sheet_image: Image = image_cache[id]
	var bands: Array = band_cache[id]
	var cell_width := sheet_image.get_width()/4
	var band: Vector2i = bands[pose]
	var crop := sheet_image.get_region(Rect2i(direction*cell_width,band.x,cell_width,band.y-band.x))
	var used := crop.get_used_rect()
	if used.size.x==0 or used.size.y==0: return legacy_texture(id,0)
	var pixels := crop.get_region(used)
	var target_height := 16 if id=="chicken" else 28
	var target_width := maxi(1,roundi(float(used.size.x)*target_height/used.size.y))
	pixels.resize(target_width,target_height,Image.INTERPOLATE_NEAREST)
	var result := ImageTexture.create_from_image(pixels)
	cache[key]=result
	return result

static func texture(id: String, frame: int) -> Texture2D:
	if id!="crow" and frame in [6,7,8]: return memorial_texture(id,{6:0,7:2,8:1}[frame])
	if id!="crow" and frame in [0,1,2,3,4,5]:
		return direction_texture(id,0,[0,3,1,0,2,0][frame])
	var key := "reduced:%s:%d" % [id,frame]
	if cache.has(key): return cache[key]
	var source := legacy_texture(id,frame)
	if source == null: return null
	var pixels := source.get_image()
	var width := 48 if frame==8 else (20 if id=="crow" else 22)
	var height := maxi(1,roundi(float(pixels.get_height())*width/pixels.get_width()))
	pixels.resize(width,height,Image.INTERPOLATE_NEAREST)
	var result := ImageTexture.create_from_image(pixels)
	cache[key]=result
	return result

static func apply_texture(sprite: Sprite2D, tex: Texture2D, height: float) -> void:
	sprite.texture=tex
	if tex==null: return
	sprite.centered=false
	sprite.offset=Vector2(-tex.get_width()/2.0,-tex.get_height())
	sprite.scale=Vector2.ONE*height/tex.get_height()
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

static func apply(sprite: Sprite2D, id: String, frame: int, height := 36.0) -> void:
	var tex := texture(id,frame)
	apply_texture(sprite,tex,height)
	if frame==8 and tex!=null:
		sprite.scale=Vector2.ONE*(height*1.6/tex.get_width())

static func find_bands(pixels: Image, expected := 4) -> Array:
	var bands: Array = []
	var start := -1
	for y in range(pixels.get_height()):
		var count := 0
		for x in range(0,pixels.get_width(),6):
			if pixels.get_pixel(x,y).a>0.5: count+=1
		if count>3 and start<0: start=y
		if count<=3 and start>=0:
			if y-start>12: bands.append(Vector2i(maxi(0,start-2),mini(pixels.get_height(),y+2)))
			start=-1
	if start>=0: bands.append(Vector2i(start,pixels.get_height()))
	if bands.size()!=expected:
		bands.clear()
		for i in range(expected): bands.append(Vector2i(i*pixels.get_height()/expected,(i+1)*pixels.get_height()/expected))
	return bands

static func memorial_texture(id: String, pose: int) -> Texture2D:
	var key := "memorial:%s:%d" % [id,pose]
	if cache.has(key): return cache[key]
	if not image_cache.has("memorial"):
		var sheet: Texture2D=load("res://art/characters/memorial-v2.png")
		image_cache["memorial"]=sheet.get_image()
		band_cache["memorial"]=find_bands(image_cache["memorial"],6)
	var pixels: Image=image_cache["memorial"]
	var band: Vector2i=band_cache["memorial"][["player","deer","horse","pig","sheep","chicken"].find(id)]
	var cell_width := pixels.get_width()/3
	var crop:=pixels.get_region(Rect2i(pose*cell_width,band.x,cell_width,band.y-band.x))
	crop=crop.get_region(crop.get_used_rect())
	var height := 16 if pose==1 else 24
	var width := maxi(1,roundi(float(crop.get_width())*height/crop.get_height()))
	crop.resize(width,height,Image.INTERPOLATE_NEAREST)
	cache[key]=ImageTexture.create_from_image(crop)
	return cache[key]
