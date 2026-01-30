extends Node

## 桥接：点击指定 HotSpot 后获得道具（Inventory.add_item）。
## 用法：挂到主场景常驻节点，配置 mapping：hotspot_id -> item_key

@export var mapping: Dictionary = {} # String -> String
@export var only_when_interactable_ok: bool = true

@onready var _event_bus: Node = get_node("/root/EventBus")
@onready var _inventory: Node = get_node("/root/Inventory")
@onready var _item_db: Node = get_node("/root/ItemDB")


func _ready() -> void:
	if not _event_bus.hotspot_action.is_connected(_on_hotspot_action):
		_event_bus.hotspot_action.connect(_on_hotspot_action)


func _on_hotspot_action(payload: Dictionary) -> void:
	if only_when_interactable_ok and not bool(payload.get("interactable_ok", false)):
		return

	var hotspot_id := str(payload.get("hotspot_id", ""))
	if hotspot_id.is_empty():
		return
	if not mapping.has(hotspot_id):
		return

	var item_key := str(mapping[hotspot_id])
	if item_key.is_empty():
		return

	# 已有则不重复获得
	if bool(_inventory.call("has_item", item_key)):
		return
	# 道具必须存在于 ItemDB
	if not bool(_item_db.call("has_item", item_key)):
		return

	# 计算起点：优先用热点 Node2D 的 global_position
	var from_pos := Vector2.ZERO
	var node_path: NodePath = payload.get("node_path", NodePath())
	if node_path != NodePath():
		var n := get_tree().root.get_node_or_null(node_path)
		if n is Node2D:
			from_pos = (n as Node2D).global_position

	# 目标/动画：交给 UI_inventory（CanvasLayer）做飞入动画
	var ui := get_tree().current_scene.get_node_or_null("UI_inventory")
	if ui != null and ui.has_method("play_item_gain_fly"):
		await ui.call("play_item_gain_fly", item_key, from_pos)

	# 动画结束后再真正加入背包 → UI 才显示“获得”
	_inventory.call("add_item", item_key)

