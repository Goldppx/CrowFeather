extends RefCounted
class_name Inventory

const DEFAULT_MAX_SLOTS := 5

class SlotData:
	var item: InventoryItemData
	var quantity: int
	
	func _init(p_item: InventoryItemData = null, p_quantity: int = 0):
		item = p_item
		quantity = p_quantity
	
	func is_empty() -> bool:
		return item == null or quantity <= 0
	
	func can_stack_with(other: InventoryItemData, max_qty: int) -> bool:
		if not item or not other:
			return false
		if not item.stackable or not other.stackable:
			return false
		if item.id != other.id:
			return false
		return quantity < max_qty

var slots: Array[SlotData] = []
var max_slots: int = DEFAULT_MAX_SLOTS

signal inventory_changed(index: int)
signal inventory_full(item_data: InventoryItemData)

func _init(p_max_slots: int = DEFAULT_MAX_SLOTS):
	max_slots = p_max_slots
	slots.clear()
	for i in range(max_slots):
		slots.append(SlotData.new(null, 0))

func add_item(item_data: InventoryItemData, amount: int = 1) -> int:
	var remaining = amount
	
	if item_data.stackable:
		for i in range(max_slots):
			if remaining <= 0:
				break
			var slot = slots[i]
			if slot.is_empty():
				continue
			if slot.item.id == item_data.id and slot.quantity < slot.item.slot_max:
				var space = slot.item.slot_max - slot.quantity
				var to_add = mini(remaining, space)
				slot.quantity += to_add
				remaining -= to_add
				inventory_changed.emit(i)
	
	for i in range(max_slots):
		if remaining <= 0:
			break
		var slot = slots[i]
		if slot.is_empty():
			var to_add = mini(remaining, item_data.slot_max)
			slots[i] = SlotData.new(item_data, to_add)
			remaining -= to_add
			inventory_changed.emit(i)
	
	if remaining > 0:
		inventory_full.emit(item_data)
	
	return amount - remaining

func remove_item(slot_index: int, amount: int = 1) -> int:
	if slot_index < 0 or slot_index >= max_slots:
		return 0
	var slot = slots[slot_index]
	if slot.is_empty():
		return 0
	var removed = mini(amount, slot.quantity)
	slot.quantity -= removed
	if slot.quantity <= 0:
		slots[slot_index] = SlotData.new(null, 0)
	inventory_changed.emit(slot_index)
	return removed

func get_slot(index: int) -> SlotData:
	if index < 0 or index >= max_slots:
		return null
	return slots[index]

func clear():
	for i in range(max_slots):
		slots[i] = SlotData.new(null, 0)
		inventory_changed.emit(i)

func is_full() -> bool:
	for slot in slots:
		if slot.is_empty():
			return false
	return true

func get_total_quantity(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if not slot.is_empty() and slot.item.id == item_id:
			total += slot.quantity
	return total

func has_item(item_id: String) -> bool:
	return get_total_quantity(item_id) > 0
