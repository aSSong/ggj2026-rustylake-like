class_name SimpleFlow
extends Resource

## 流程图唯一标识。
## 建议与房间/关卡名对应，便于生成内部标识和调试日志。
@export var graph_id: String = ""
## 起始步骤列表。
## 这些 step 会在 start_flow() 时直接解锁，可用于单起点或多起点并行。
@export var start_steps: PackedStringArray = PackedStringArray()
## 简化后的步骤列表。
## 每一步只描述“意图”和“目标”，由编译器转成底层 FlowGraph。
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
