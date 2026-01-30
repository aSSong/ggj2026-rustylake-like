extends Node

## 道具数据库：扫描 items 目录下的 InventoryItem.tres

@export var items_dir: String = "res://items"

var _items_by_key: Dictionary = {} # String -> InventoryItem(Resource)


func _ready() -> void:
	reload()


func reload() -> void:
	_items_by_key.clear()

	var dir := DirAccess.open(items_dir)
	if dir == null:
		push_warning("ItemDB: cannot open dir: %s" % items_dir)
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not file_name.ends_with(".tres"):
			continue

		var path := "%s/%s" % [items_dir.trim_suffix("/"), file_name]
		var res := load(path)
		if res == null:
			push_warning("ItemDB: failed loading: %s" % path)
			continue

		# 只要具备 key 字段就接受（避免类型解析问题）
		var key := str(res.get("key"))
		if key.is_empty():
			push_warning("ItemDB: item has empty key: %s" % path)
			continue

		if _items_by_key.has(key):
			push_warning("ItemDB: duplicate key '%s' (%s)" % [key, path])
			continue

		_items_by_key[key] = res

	dir.list_dir_end()


func has_item(key: String) -> bool:
	return _items_by_key.has(key)


func get_item(key: String) -> Resource:
	return _items_by_key.get(key, null)


func all_keys() -> PackedStringArray:
	var out := PackedStringArray()
	for k in _items_by_key.keys():
		out.append(str(k))
	return out

