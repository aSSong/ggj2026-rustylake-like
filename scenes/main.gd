extends Node2D

## 最小验证监听：打印 HotSpot 点击事件 payload。
## 之后你可以删掉或替换成 RoomController/UI 系统。

@export var print_hotspot_payload: bool = true
@export var debug_add_inventory_item_on_start: bool = false
@export var debug_inventory_item_key: String = "test_key"


func _ready() -> void:
	var scene_flow: Node = get_node("/root/SceneFlow")
	scene_flow.start_game()

	if debug_add_inventory_item_on_start:
		var inv: Node = get_node("/root/Inventory")
		inv.call("add_item", debug_inventory_item_key)

	var event_bus: Node = get_node("/root/EventBus")
	if not event_bus.hotspot_action.is_connected(_on_hotspot_action):
		event_bus.hotspot_action.connect(_on_hotspot_action)


func _on_hotspot_action(payload: Dictionary) -> void:
	if print_hotspot_payload:
		print(payload)

