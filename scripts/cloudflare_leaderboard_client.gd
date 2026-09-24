extends Node

signal scores_loaded(scores: Array)
signal score_submitted()
signal request_failed(message: String)

@export var api_base_url := ""
@export var submit_token := ""

var _load_http: HTTPRequest
var _submit_http: HTTPRequest

func _ready() -> void:
	_load_http = HTTPRequest.new()
	add_child(_load_http)
	_load_http.request_completed.connect(_on_load_request_completed)

	_submit_http = HTTPRequest.new()
	add_child(_submit_http)
	_submit_http.request_completed.connect(_on_submit_request_completed)

func submit_score(player_name: String, collection: String, level: int, score: int, metadata := {}) -> void:
	if not _has_api_url():
		return

	var payload := {
		"playerName": player_name,
		"collection": collection,
		"level": level,
		"score": score,
		"metadata": metadata,
	}
	if not submit_token.is_empty():
		payload["token"] = submit_token

	var err := _submit_http.request(
		"%s/scores" % api_base_url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	if err != OK:
		request_failed.emit("Could not submit score.")

func load_scores(collection := "", level := 0, limit := 10) -> void:
	if not _has_api_url():
		return

	var query := ["limit=%d" % limit]
	if not collection.is_empty() and level > 0:
		query.append("collection=%s" % collection.uri_encode())
		query.append("level=%d" % level)

	var err := _load_http.request("%s/scores?%s" % [api_base_url, "&".join(query)])
	if err != OK:
		request_failed.emit("Could not load scores.")

func _has_api_url() -> bool:
	if api_base_url.is_empty():
		request_failed.emit("Leaderboard API URL is not configured.")
		return false
	return true

func _on_load_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		request_failed.emit("Leaderboard request failed.")
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Leaderboard response was invalid.")
		return

	scores_loaded.emit(parsed.get("scores", []))

func _on_submit_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		request_failed.emit("Leaderboard request failed.")
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit("Leaderboard response was invalid.")
		return

	score_submitted.emit()
