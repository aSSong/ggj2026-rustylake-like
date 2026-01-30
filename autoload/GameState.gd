extends Node

## 轻量世界状态：flags + inventory（背包物品）
## - flags：Dictionary[String, bool]
## - inventory：Array[String]
##
## HotSpot 条件评估逻辑依赖这里的查询 API。

signal flag_changed(flag_name: String, value: bool)
signal inventory_changed()

var flags: Dictionary = {}
var inventory: Array[String] = []

func _to_packed_string_array(v: Variant) -> PackedStringArray:
	if v is PackedStringArray:
		return v
	var out := PackedStringArray()
	if v is Array:
		for x in v:
			out.append(str(x))
	return out


func has_flag(flag_name: String) -> bool:
	return bool(flags.get(flag_name, false))


func set_flag(flag_name: String, value: bool = true) -> void:
	var prev := bool(flags.get(flag_name, false))
	flags[flag_name] = value
	if prev != value:
		flag_changed.emit(flag_name, value)


func has_all_flags(names: PackedStringArray) -> bool:
	for n in names:
		if not has_flag(n):
			return false
	return true


func has_any_flag(names: PackedStringArray) -> bool:
	if names.is_empty():
		return true
	for n in names:
		if has_flag(n):
			return true
	return false


func forbids_any_flags(names: PackedStringArray) -> bool:
	for n in names:
		if has_flag(n):
			return true
	return false


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func add_item(item_id: String) -> void:
	if inventory.has(item_id):
		return
	inventory.append(item_id)
	inventory_changed.emit()


func remove_item(item_id: String) -> void:
	var idx := inventory.find(item_id)
	if idx == -1:
		return
	inventory.remove_at(idx)
	inventory_changed.emit()


func has_items(item_ids: PackedStringArray) -> bool:
	for id in item_ids:
		if not has_item(id):
			return false
	return true


func check_condition_set(condition_set: Resource) -> bool:
	# 为避免循环依赖，这里用 duck-typing（字段名约定）而不是直接引用 class_name。
	if condition_set == null:
		return true

	var requires_flags_all := _to_packed_string_array(condition_set.get("requires_flags_all"))
	var requires_flags_any := _to_packed_string_array(condition_set.get("requires_flags_any"))
	var requires_items := _to_packed_string_array(condition_set.get("requires_items"))
	var forbids_flags := _to_packed_string_array(condition_set.get("forbids_flags"))

	if not has_all_flags(requires_flags_all):
		return false
	if not has_any_flag(requires_flags_any):
		return false
	if not has_items(requires_items):
		return false
	if forbids_any_flags(forbids_flags):
		return false
	return true
