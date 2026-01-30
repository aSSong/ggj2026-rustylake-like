extends Node

## 背包系统（独立入口）：
## - 只存 item key（String）
## - ItemDB 用 key 查询资源
## - 与 GameState.inventory 同步（GameState 是 HotSpot 条件判断的真源）

signal item_added(key: String)
signal item_removed(key: String)
signal selection_changed(selected_key: String)

@export var default_selected_on_add: bool = false

var _selected_key: String = ""

@onready var _game_state: Node = get_node("/root/GameState")
@onready var _item_db: Node = get_node("/root/ItemDB")


func get_items() -> Array[String]:
	return _game_state.inventory.duplicate()


func has_item(key: String) -> bool:
	return bool(_game_state.call("has_item", key))


func add_item(key: String) -> bool:
	if key.is_empty():
		return false
	if not bool(_item_db.call("has_item", key)):
		push_warning("Inventory: unknown item key: %s" % key)
		return false
	if has_item(key):
		return false

	_game_state.call("add_item", key)
	item_added.emit(key)

	if default_selected_on_add:
		select_item(key)
	return true


func remove_item(key: String) -> bool:
	if key.is_empty():
		return false
	if not has_item(key):
		return false

	_game_state.call("remove_item", key)
	item_removed.emit(key)

	if _selected_key == key:
		select_item("")
	return true


func get_selected_key() -> String:
	return _selected_key


func select_item(key: String) -> void:
	if key == _selected_key:
		return
	if not key.is_empty() and not has_item(key):
		return
	_selected_key = key
	selection_changed.emit(_selected_key)

