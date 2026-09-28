extends Node
## Reserved asynchronous transport. Disabled until an operator configures a backend.
## Production API keys belong on that backend, never in a shipped game or save file.
signal completed(snapshot: Dictionary, suggestion: Variant)
var enabled := false
var endpoint := ""
var model := ""
var timeout_seconds := 8.0
var pending: Dictionary = {}
var request: HTTPRequest

func _ready() -> void:
	request = HTTPRequest.new()
	request.timeout = timeout_seconds
	add_child(request)
	request.request_completed.connect(_completed)

func request_judgment(snapshot: Dictionary, body: Dictionary) -> void:
	if not enabled or endpoint.is_empty() or model.is_empty():
		completed.emit(snapshot,null)
		return
	if not pending.is_empty():
		return
	if not endpoint.begins_with("https://") and not endpoint.begins_with("http://127.0.0.1:"):
		completed.emit(snapshot,null)
		return
	pending = snapshot.duplicate(true)
	request.timeout = timeout_seconds
	var payload := body.duplicate(true)
	payload.model = model
	var error := request.request(endpoint,PackedStringArray(["Content-Type: application/json"]),HTTPClient.METHOD_POST,JSON.stringify(payload))
	if error != OK:
		_finish(null)

func cancel() -> void:
	if is_instance_valid(request):
		request.cancel_request()
	pending.clear()

func _completed(result: int, code: int, _headers: PackedStringArray, data: PackedByteArray) -> void:
	if pending.is_empty():
		return
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300 or data.size() > 65536:
		_finish(null)
		return
	var json := JSON.new()
	if json.parse(data.get_string_from_utf8()) != OK or not json.data is Dictionary:
		_finish(null)
		return
	var value: Dictionary = json.data
	# Support a direct backend judgment or the standard DeepSeek chat response envelope.
	if value.get("choices") is Array and not value.choices.is_empty():
		var choice = value.choices[0]
		if choice is Dictionary and choice.get("message") is Dictionary:
			var content = choice.message.get("content","")
			var parsed := JSON.new()
			if content is String and parsed.parse(content) == OK:
				_finish(parsed.data)
				return
		_finish(null)
	else:
		_finish(value)

func _finish(value: Variant) -> void:
	var snapshot := pending.duplicate(true)
	pending.clear()
	completed.emit(snapshot,value)
