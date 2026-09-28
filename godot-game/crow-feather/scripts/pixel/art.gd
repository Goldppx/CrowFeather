extends RefCounted
## One transparent 4x4 atlas. Every sprite is anchored at its feet for Y sorting.
const ATLAS_PATH := "res://art/pixel/crowfeather_atlas.png"

static func texture(index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ATLAS_PATH)
	var cell := atlas.atlas.get_size() / 4.0
	var origin := Vector2(index % 4, index / 4) * cell
	var region_size := cell
	# Generated props extend below a regular grid cell: use explicit row bounds
	# so tree roots never bleed into the item icons beneath them.
	if index >= 8 and index < 12:
		region_size.y = 370.0
	elif index >= 12:
		origin.y = 1000.0
		region_size.y = 254.0
	atlas.region = Rect2(origin, region_size)
	atlas.filter_clip = true
	return atlas

static func sprite(index: int, cell_size: float = 48.0) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = texture(index)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.scale = Vector2.ONE * cell_size / node.texture.get_width()
	node.centered = false
	var foot_y := 290.0
	if index >= 8 and index < 12:
		foot_y = [340.0, 342.0, 344.0, 352.0][index - 8]
	elif index >= 12:
		foot_y = 212.0
	node.offset = Vector2(-node.texture.get_width() / 2.0, -foot_y)
	return node
