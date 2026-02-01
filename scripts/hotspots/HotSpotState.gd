class_name HotSpotState
extends Resource

@export var state_id: String = ""
@export var priority: int = 0

@export var conditions: Resource
@export var texture: Texture2D
## 当 texture 为空时，是否强制清空热点的 Sprite2D.texture（用于开关显示）
@export var clear_texture_when_null: bool = false
## 可拖拽 dtl 文件到 Inspector
@export_file("*.dtl") var click_dialog_timeline: String = ""
@export_file("*.dtl") var blocked_dialog_timeline: String = ""

@export var actions: Array[Resource] = []
@export var feedback: Resource

