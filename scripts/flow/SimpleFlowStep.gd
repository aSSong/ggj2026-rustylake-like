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

## 步骤唯一 ID。
## 供 after_step_ids / next_step_ids 引用，建议使用稳定且可读的名字。
@export var step_id: String = ""
## 前置步骤列表。
## 这些步骤完成后，本步骤才会被解锁；无需手写 `<step>_completed` flag。
@export var after_step_ids: PackedStringArray = PackedStringArray()
## 后继步骤列表。
## 当前步骤完成后，会自动解锁这里列出的步骤。
@export var next_step_ids: PackedStringArray = PackedStringArray()
## 备注说明。
## 仅用于作者阅读和 Inspector 辅助，不参与运行时逻辑。
@export_multiline var note: String = ""

@export_group("Intent")
## 步骤类型。
## 根据类型填写下面对应字段即可，其余字段可以留空。
@export_enum(
	"Dialog | 播放对话并等待结束",
	"Wait Hotspot | 等待点击某个热点",
	"Delay | 延迟一段时间",
	"Set Flag | 立即设置某个 flag",
	"Change Room | 立即切换房间",
	"Wait Flag | 等待某个已有 flag 成立"
) var kind: int = StepKind.DIALOG
## Dialog 类型使用的 Dialogic timeline。
## 建议直接填 `res://...` 路径。
@export_file("*.dtl") var timeline: String = ""
## Wait Hotspot 类型使用的 hotspot_id。
## 例如 `HS_01`、`HS_door`。
@export var hotspot_id: String = ""
## Delay 类型等待的秒数。
## 可填小数，例如 `0.5`、`1.2`。
@export var delay_sec: float = 0.0
## Set Flag / Wait Flag 类型使用的 flag 名称。
@export var flag_name: String = ""
## Set Flag 类型写入的值。
## Wait Flag 类型下此字段无效。
@export var flag_value: bool = true
## Change Room 类型使用的 room_id。
## 必须存在于 SceneFlow 的房间注册表中。
@export var room_id: String = ""
