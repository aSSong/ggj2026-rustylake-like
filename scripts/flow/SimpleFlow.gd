class_name SimpleFlow
extends Resource

@export var graph_id: String = ""
@export var start_steps: PackedStringArray = PackedStringArray()
@export var steps: Array[Resource] = []


func all_step_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for step in steps:
		if step == null:
			continue
		var step_id := str(step.get("step_id"))
		if step_id.is_empty():
			continue
		out.append(step_id)
	return out
