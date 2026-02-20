extends Node


signal player_connected(alias : String, id : int)
signal player_disconnected(alias : String, id : int)


const PLAYER_TIMEOUT_SEC = 10


var _players : Dictionary[String, int] = {}
var _timeout_queue : Array[String] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WebSocketServer.player_registered.connect(_on_player_registered)


func _on_player_registered(id : int, alias : String) -> void:
	var is_reconnect := _timeout_queue.has(alias)
	_players[alias] = id
	if is_reconnect:
		_timeout_queue.erase(alias)


func _on_peer_disconnected(id : int) -> void:
	var alias : String = _players.find_key(id)
	if not alias: return
	_timeout_queue.append(alias)
	await get_tree().create_timer(PLAYER_TIMEOUT_SEC).timeout
	if not _timeout_queue.has(alias): return
	_players.erase(alias)
	player_disconnected.emit(alias, id)
