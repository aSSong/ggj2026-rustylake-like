class_name SimpleFlowCompiler
extends RefCounted

const _FlowGraphScript := preload("res://scripts/flow/FlowGraph.gd")
const _FlowStepScript := preload("res://scripts/flow/FlowStep.gd")
const _FlowActionScript := preload("res://scripts/flow/FlowAction.gd")
const _SimpleFlowStepScript := preload("res://scripts/flow/SimpleFlowStep.gd")


func compile(simple_flow: Resource) -> Dictionary:
	if simple_flow == null:
		return {
			"graph": null,
			"dialog_mapping": {},
			"delay_mapping": {},
		}

	var graph := _FlowGraphScript.new()
	graph.graph_id = str(simple_flow.get("graph_id"))
	graph.start_step_ids = _copy_packed_string_array(simple_flow.get("start_steps"))

	var steps: Array[Resource] = []
	var dialog_mapping := {}
	var delay_mapping := {}

	for raw_step in simple_flow.get("steps"):
		if raw_step == null:
			continue

		var compiled_step := _compile_step(graph.graph_id, raw_step, dialog_mapping, delay_mapping)
		if compiled_step != null:
			steps.append(compiled_step)

	graph.steps = steps
	graph.rebuild_index()

	return {
		"graph": graph,
		"dialog_mapping": dialog_mapping,
		"delay_mapping": delay_mapping,
	}


func hotspot_done_flag_for(hotspot_id: String) -> String:
	var token := hotspot_id.strip_edges().to_lower()
	if token.is_empty():
		return ""
	if token.begins_with("hs_"):
		return "%s_done" % token
	return "hs_%s_done" % token


func _compile_step(graph_id: String, raw_step: Resource, dialog_mapping: Dictionary, delay_mapping: Dictionary) -> Resource:
	var step_id := str(raw_step.get("step_id"))
	if step_id.is_empty():
		return null

	var compiled := _FlowStepScript.new()
	compiled.step_id = step_id
	compiled.thread_id = graph_id
	compiled.description = str(raw_step.get("note"))
	compiled.enable_flags_all = _after_steps_to_flags(raw_step.get("after_step_ids"))
	compiled.next_ids = _copy_packed_string_array(raw_step.get("next_step_ids"))

	var kind := int(raw_step.get("kind"))
	match kind:
		_SimpleFlowStepScript.StepKind.DIALOG:
			var timeline := str(raw_step.get("timeline"))
			if timeline.is_empty():
				return compiled
			var start_flag := _internal_flag(graph_id, step_id, "start")
			var done_flag := _internal_flag(graph_id, step_id, "done")
			compiled.on_enter_actions = [_new_set_flag_action(start_flag, true)]
			compiled.complete_flags_all = PackedStringArray([done_flag])
			dialog_mapping[start_flag] = {
				"timeline": timeline,
				"done_flag": done_flag,
			}

		_SimpleFlowStepScript.StepKind.WAIT_HOTSPOT:
			var hotspot_id := str(raw_step.get("hotspot_id"))
			var done_flag := hotspot_done_flag_for(hotspot_id)
			if not done_flag.is_empty():
				compiled.complete_flags_all = PackedStringArray([done_flag])

		_SimpleFlowStepScript.StepKind.DELAY:
			var start_flag := _internal_flag(graph_id, step_id, "start")
			var done_flag := _internal_flag(graph_id, step_id, "done")
			compiled.on_enter_actions = [_new_set_flag_action(start_flag, true)]
			compiled.complete_flags_all = PackedStringArray([done_flag])
			delay_mapping[start_flag] = {
				"delay": float(raw_step.get("delay_sec")),
				"done_flag": done_flag,
			}

		_SimpleFlowStepScript.StepKind.SET_FLAG:
			var target_flag := str(raw_step.get("flag_name"))
			if target_flag.is_empty():
				return compiled
			var value := bool(raw_step.get("flag_value"))
			var done_flag := _internal_flag(graph_id, step_id, "done")
			compiled.on_enter_actions = [
				_new_set_flag_action(target_flag, value),
				_new_set_flag_action(done_flag, true),
			]
			compiled.complete_flags_all = PackedStringArray([done_flag])

		_SimpleFlowStepScript.StepKind.CHANGE_ROOM:
			var room_id := str(raw_step.get("room_id"))
			if room_id.is_empty():
				return compiled
			var done_flag := _internal_flag(graph_id, step_id, "done")
			compiled.on_enter_actions = [
				_new_change_room_action(room_id),
				_new_set_flag_action(done_flag, true),
			]
			compiled.complete_flags_all = PackedStringArray([done_flag])

		_SimpleFlowStepScript.StepKind.WAIT_FLAG:
			var wait_flag := str(raw_step.get("flag_name"))
			if not wait_flag.is_empty():
				compiled.complete_flags_all = PackedStringArray([wait_flag])

	return compiled


func _after_steps_to_flags(after_step_ids: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	for step_id in _copy_packed_string_array(after_step_ids):
		out.append("%s_completed" % str(step_id))
	return out


func _copy_packed_string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return value
	var out := PackedStringArray()
	if value is Array:
		for entry in value:
			out.append(str(entry))
	return out


func _internal_flag(graph_id: String, step_id: String, suffix: String) -> String:
	return "__sf_%s_%s_%s" % [graph_id.to_snake_case(), step_id.to_snake_case(), suffix]


func _new_set_flag_action(flag_name: String, value: bool) -> Resource:
	var action := _FlowActionScript.new()
	action.type = _FlowActionScript.ActionType.SET_FLAG
	action.flag_name = flag_name
	action.flag_value = value
	return action


func _new_change_room_action(room_id: String) -> Resource:
	var action := _FlowActionScript.new()
	action.type = 1 as _FlowActionScript.ActionType
	action.room_id = room_id
	return action
