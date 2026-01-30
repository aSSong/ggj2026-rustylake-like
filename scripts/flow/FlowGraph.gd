class_name FlowGraph
extends Resource

@export var graph_id: String = ""
@export var start_step_ids: PackedStringArray = PackedStringArray()
@export var steps: Array[Resource] = []

var _index: Dictionary = {}


func rebuild_index() -> void:
	_index.clear()
	for s in steps:
		if s == null:
			continue
		if str(s.get("step_id")).is_empty():
			continue
		_index[str(s.get("step_id"))] = s


func get_step(step_id: String) -> Resource:
	if _index.is_empty():
		rebuild_index()
	return _index.get(step_id, null)


func all_step_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for s in steps:
		if s and not str(s.get("step_id")).is_empty():
			out.append(str(s.get("step_id")))
	return out
