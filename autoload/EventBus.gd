extends Node

## 全局事件总线：HotSpotArea 等只负责发事件，不直接执行逻辑。
##
## 统一 payload 结构建议：
## {
##   "hotspot_id": String,
##   "node_path": NodePath,
##   "visible_ok": bool,
##   "interactable_ok": bool,
##   "actions": Array[Dictionary],
##   "feedback": Dictionary,
##   "timestamp_ms": int,
## }
@warning_ignore("unused_signal")
signal hotspot_action(payload: Dictionary)
