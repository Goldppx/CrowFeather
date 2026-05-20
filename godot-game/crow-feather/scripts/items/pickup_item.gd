extends StaticBody3D
class_name PickupItem

@export var item_data: InventoryItemData

var _original_y: float

func _ready():
	_original_y = position.y
	
	if item_data and item_data.world_model:
		var model = item_data.world_model.instantiate()
		add_child(model)
	
	# 浮动动画
	_start_floating()

func _start_floating():
	var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _original_y + 0.2, 1.2)
	tween.tween_property(self, "position:y", _original_y, 1.2)

func get_interact_text() -> String:
	if item_data and not item_data.item_name.is_empty():
		return "按 E 拾取 %s" % item_data.item_name
	return "按 E 拾取"
