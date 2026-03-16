class_name SimpleFlowStep
extends Resource

enum StepKind {
	DIALOG,
	WAIT_HOTSPOT,
	DELAY,
	SET_FLAG,
	CHANGE_ROOM,
	WAIT_FLAG,
}

@export var step_id: String = ""
@export var after_step_ids: PackedStringArray = PackedStringArray()
@export var next_step_ids: PackedStringArray = PackedStringArray()
@export_multiline var note: String = ""

@export_group("Intent")
@export var kind: StepKind = StepKind.DIALOG
@export_file("*.dtl") var timeline: String = ""
@export var hotspot_id: String = ""
@export var delay_sec: float = 0.0
@export var flag_name: String = ""
@export var flag_value: bool = true
@export var room_id: String = ""
