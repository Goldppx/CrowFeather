extends StaticBody3D
class_name PickupItem

@export var item_data: InventoryItemData

func _ready():
	if item_data and item_data.world_model:
		var model = item_data.world_model.instantiate()
		add_child(model)

func get_interact_text() -> String:
	if item_data and not item_data.item_name.is_empty():
		return "按 E 拾取 %s" % item_data.item_name
	return "按 E 拾取"
