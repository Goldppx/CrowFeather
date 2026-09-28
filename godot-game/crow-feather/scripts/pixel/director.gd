extends RefCounted
## Offline by default. Provider suggestions can only choose an authored eligible edge.
## A future transport calls the configured backend; API keys never enter saves or clients.
var provider: Callable
var last_reason := "使用本地剧情规则"
var sequence := 0

func context(story, actions: Array) -> Dictionary:
	sequence += 1
	return {"request_id": sequence, "node": story.state.node, "allowed_nodes": story.available(),
		"erased": story.state.erased, "accepted": story.state.accepted,
		"flags": story.state.flags.duplicate(true), "recent_actions": actions.slice(-12)}

func request_body(snapshot: Dictionary, model: String) -> Dictionary:
	return {"model": model, "response_format": {"type": "json_object"},
		"max_tokens": 256, "messages": [
		{"role": "system", "content": "Return JSON only: request_id, node, reason. Choose node only from allowed_nodes. Judge player actions at this checkpoint. Never override a player's explicit verdict or invent facts."},
		{"role": "user", "content": JSON.stringify(snapshot)}]}

func choose(story, actions: Array, simulated: Variant = null) -> String:
	var snapshot := context(story, actions)
	var allowed: Array = snapshot.allowed_nodes
	if allowed.is_empty():
		return ""
	var answer: Variant = simulated
	if answer == null and provider.is_valid():
		answer = provider.call(snapshot)
	if answer is String:
		var parser := JSON.new()
		answer = parser.data if parser.parse(answer) == OK else null
	if answer is Dictionary and typeof(answer.get("node")) == TYPE_STRING:
		if answer.node in allowed and int(answer.get("request_id", snapshot.request_id)) == int(snapshot.request_id):
			last_reason = str(answer.get("reason", "已校验的分支建议")).left(180)
			return answer.node
	last_reason = "离线或无效建议：回退到本地合法分支"
	return str(allowed[0])
