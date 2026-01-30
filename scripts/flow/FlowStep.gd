class_name FlowStep
extends Resource

@export var step_id: String = ""
@export var thread_id: String = ""
@export_multiline var description: String = ""

@export var enable_flags_all: PackedStringArray = PackedStringArray()
@export var enable_flags_any: PackedStringArray = PackedStringArray()
@export var enable_forbids_flags: PackedStringArray = PackedStringArray()

@export var complete_flags_all: PackedStringArray = PackedStringArray()
@export var complete_flags_any: PackedStringArray = PackedStringArray()

@export var on_enter_actions: Array[Resource] = []
@export var on_complete_actions: Array[Resource] = []

@export var next_ids: PackedStringArray = PackedStringArray()


func is_enabled(game_state: Node) -> bool:
	if game_state == null:
		return false

	# enable_flags_all：全部满足
	for f in enable_flags_all:
		if not bool(game_state.call("has_flag", f)):
			return false

	# enable_flags_any：为空则不限制；否则至少一个满足
	if not enable_flags_any.is_empty():
		var any_ok := false
		for f in enable_flags_any:
			if bool(game_state.call("has_flag", f)):
				any_ok = true
				break
		if not any_ok:
			return false

	# enable_forbids_flags：这些 flag 任意一个为 true 都不允许
	for f in enable_forbids_flags:
		if bool(game_state.call("has_flag", f)):
			return false

	return true


func is_complete(game_state: Node) -> bool:
	if game_state == null:
		return false

	for f in complete_flags_all:
		if not bool(game_state.call("has_flag", f)):
			return false

	if not complete_flags_any.is_empty():
		var any_ok := false
		for f in complete_flags_any:
			if bool(game_state.call("has_flag", f)):
				any_ok = true
				break
		if not any_ok:
			return false

	# 如果完全没有完成条件，默认不自动完成
	if complete_flags_all.is_empty() and complete_flags_any.is_empty():
		return false

	return true

