extends RefCounted
## Authored funnel graph. Add local nodes; return to a named convergence point.
const ACTORS := ["deer", "horse", "pig", "sheep", "chicken"]
const NAMES := {"deer": "鹿头人", "horse": "马人", "pig": "猪头人", "sheep": "羊人", "chicken": "鸡"}
const WEIGHTS := {"deer": 2, "horse": 4, "pig": 2, "sheep": 3, "chicken": 1}
const REGIONS := {
	"deer": {"name": "苔庭", "fog": Color("799e96"), "ground": Color("253c38")},
	"horse": {"name": "驿路", "fog": Color("879dcc"), "ground": Color("283445")},
	"pig": {"name": "旧集市", "fog": Color("bb8588"), "ground": Color("432e3a")},
	"sheep": {"name": "钟坡", "fog": Color("b1a4c9"), "ground": Color("353245")},
	"chicken": {"name": "谷仓", "fog": Color("b3ae79"), "ground": Color("393b2b")}
}
const TEXT := {
	"deer": "枝角垂向露水。衣袋里的小锁坠仍在发亮。\n这里的雾带着苔色，像有一片林子在等待名字。",
	"horse": "三条腿的信使终于停了下来。邮袋里仍有未送出的信。\n他说过：哥们，消息总得有人送到。",
	"pig": "磨损的铜表停在同一刻。无人认领的摊位只剩雨声。\n雾里微红的余温，还记得这里曾经热闹。",
	"sheep": "小铃没有再响。灰蓝的披肩仍细心折在身旁。\n风从钟坡经过，却绕过了这个名字。",
	"chicken": "这是一只普通的鸡。谷粒洒在脚边。\n没人替它写过故事，但它也曾改变过一个清晨。"
}
var graph: Dictionary = {}
var state: Dictionary

func _init() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/story_graph.json"))
	if parsed is Dictionary:
		graph = parsed

func bind(saved: Dictionary) -> void:
	state = saved

func available() -> Array:
	var node: Dictionary = graph.get(state.get("node", "arrival"), {})
	var options: Array = []
	for edge in node.get("edges", []):
		var condition: String = edge.get("flag", "")
		if condition.is_empty() or bool(state.flags.get(condition, false)) == bool(edge.get("equals", true)):
			options.append(edge.to)
	return options

func advance(target: String) -> bool:
	if target not in available() or not graph.has(target):
		return false
	state.history.append({"from": state.node, "to": target})
	state.node = target
	return true

func judge(id: String, erase: bool) -> bool:
	if id not in ACTORS or state.decisions.has(id):
		return false
	state.decisions[id] = "erased" if erase else "accepted"
	state.flags[id + "_existed"] = not erase
	state.flags[id + "_erased"] = erase
	if erase:
		state.erased += 1
		state.distortion += WEIGHTS[id]
	else:
		state.accepted += 1
	state.flags.all_judged = state.decisions.size() == ACTORS.size()
	state.flags.mail_route = not bool(state.flags.get("horse_erased", false))
	state.flags.market_open = not bool(state.flags.get("pig_erased", false))
	state.flags.bell_remembered = not bool(state.flags.get("sheep_erased", false))
	state.history.append({"actor": id, "choice": state.decisions[id]})
	return true

func ending() -> String:
	if state.decisions.size() < ACTORS.size():
		return ""
	var ratio := float(state.erased) / ACTORS.size()
	if ratio >= 0.8:
		return "因果坍塌"
	if ratio <= 0.2:
		return "顺应宿命"
	return "余雾未散"
