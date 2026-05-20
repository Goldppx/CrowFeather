extends Resource
class_name InventoryItemData

@export var id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var slot_max: int = 99
@export var world_model: PackedScene       # 3D 场景，用于在世界中显示的模型
