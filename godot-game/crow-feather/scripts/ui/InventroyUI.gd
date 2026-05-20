extends Control
class_name InventroyUI

## 物品栏面板——屏幕顶部 5 格
## 纯锚点定位，每格 = 1/7 总宽，间距 = 1/14 总宽

var slot_count: int = 5
var _slot_uis: Array[InventorySlotUI] = []

var _slot_scene = preload("res://scenes/inventroy/InventoryItem.tscn")

func _ready():
	# 创建 5 个格子，用锚点定位
	for i in range(slot_count):
		var slot: InventorySlotUI = _slot_scene.instantiate()
		add_child(slot)
		slot.name = "Slot%d" % i
		_slot_uis.append(slot)
	
	_position_slots()
	_ready_done = true

## 计算并设置每个格子的锚点
func _position_slots():
	var total_w = size.x
	if total_w <= 0:
		_position_slots.call_deferred()
		return
	
	# 每格占 1/7 总宽，间距占 1/14 总宽
	var slot_ratio = 1.0 / 7.0
	var gap_ratio = slot_ratio / 2.0
	
	for i in range(slot_count):
		var slot = _slot_uis[i]
		var left = i * (slot_ratio + gap_ratio)
		var right = left + slot_ratio
		slot.anchor_left = left
		slot.anchor_right = right
		slot.anchor_top = 0.0
		slot.anchor_bottom = 1.0
		slot.offset_left = 0
		slot.offset_right = 0
		slot.offset_top = 0
		slot.offset_bottom = 0

var _ready_done := false

func _notification(what):
	if what == NOTIFICATION_RESIZED and _ready_done:
		_position_slots()

## 刷新全部格子
func refresh_from(inventory: Inventory):
	for i in range(min(slot_count, inventory.max_slots)):
		if i < _slot_uis.size():
			_slot_uis[i].setup(inventory.get_slot(i))

## 刷新单个格子
func refresh_slot(index: int, inventory: Inventory):
	if index >= 0 and index < _slot_uis.size():
		_slot_uis[index].setup(inventory.get_slot(index))

## 获取指定格子的 UI 控件
func get_slot_ui(index: int) -> InventorySlotUI:
	if index >= 0 and index < _slot_uis.size():
		return _slot_uis[index]
	return null
