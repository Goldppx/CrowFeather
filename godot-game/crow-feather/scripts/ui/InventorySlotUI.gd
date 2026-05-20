extends Control
class_name InventorySlotUI

@onready var icon: TextureRect = %Icon
@onready var label: Label = %Label

var slot_data: Inventory.SlotData:
	set(value):
		slot_data = value
		_update_display()

func setup(data: Inventory.SlotData):
	slot_data = data

func _update_display():
	if slot_data and not slot_data.is_empty():
		icon.texture = slot_data.item.icon
		if slot_data.quantity > 1:
			label.text = "x%d" % slot_data.quantity
		else:
			label.text = slot_data.item.item_name
		modulate = Color.WHITE
	else:
		icon.texture = null
		label.text = ""
		modulate = Color(1, 1, 1, 0.3)
