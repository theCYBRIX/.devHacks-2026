extends Node


signal player_connected(alias : String, id : int)
signal player_disconnected(alias : String, id : int)
signal player_input(alias : String, inputs : Dictionary)


const PLAYER_TIMEOUT_SEC = 10


const PLAYER_COLORS : Array[Color] = [
	Color.RED,
	Color.BLUE,
	Color.YELLOW,
	Color.GREEN,
	Color.PURPLE,
	Color.ORANGE,
	Color.DEEP_PINK,
	Color.DARK_TURQUOISE
]


var _player_ids : Dictionary[String, int] = {}
var _player_aliases : Dictionary[int, String] = {}
var _player_inputs : Dictionary[String, Dictionary] = {}
var _player_colors : Dictionary[String, Color] = {}
var _timeout_queue : Array[String] = []
var _available_colors : Array[Color] = PLAYER_COLORS.duplicate()
var _player_numbers : Dictionary[String, int] = {}
var _available_numbers : Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WebSocketServer.peer_message.connect(_on_peer_message)


func get_player_color(alias : String) -> Color:
	return _player_colors.get(alias)

func get_player_number(alias : String) -> int:
	return _player_numbers.get(alias)


func get_player_count() -> int:
	return _player_ids.size()


func _on_peer_message(id : int, message : String) -> void:
	var inputs = JSON.parse_string(message)
	print("message received: " +  message)
	if not inputs:
		print("ERROR: Failed to parse packet from peer %d:\n\t%s" % [id, message])
		return
	var alias = _player_aliases.get(id)
	if alias:
		player_input.emit(alias, inputs.get("joystickData", {}))
	elif inputs.has("name"):
		_handle_alias_request(id, inputs)


func _on_player_registered(id : int, alias : String) -> void:
	var is_reconnect := _timeout_queue.has(alias)
	_player_ids[alias] = id
	_player_aliases[id] = alias
	if is_reconnect:
		_timeout_queue.erase(alias)
	else:
		var player_col : Color = _available_colors.pop_back() if not _player_colors.is_empty() else get_random_color()
		_player_colors[alias] = player_col
		_player_numbers[alias] = _available_numbers.pop_front()
		player_connected.emit(alias, id)


func _on_peer_disconnected(id : int) -> void:
	var alias : String = _player_aliases.get(id)
	_player_aliases.erase(id)
	if not alias: return
	_timeout_queue.append(alias)
	await get_tree().create_timer(PLAYER_TIMEOUT_SEC).timeout
	if not _timeout_queue.has(alias): return
	_player_ids.erase(alias)
	var player_col : Color = _player_colors[alias]
	_player_colors.erase(alias)
	var player_number = _player_numbers[alias]
	_player_numbers.erase(alias)
	_available_numbers.append(player_number)
	_available_numbers.sort()
	if PLAYER_COLORS.has(player_col): _available_colors.append(player_col)
	player_disconnected.emit(alias, id)


func get_random_color() -> Color:
	return Color(100 + randf_range(0, 155), 100 + randf_range(0, 155), 100 + randf_range(0, 155))


func _handle_alias_request(peer_id : int, data : Dictionary) -> void:
	var alias = data.name
	var response : String
	if _player_ids.has(alias):
		response = JSON.stringify({ "accepted": false })
		return
	
	_on_player_registered(peer_id, alias)
	response = JSON.stringify({
		"accepted": true,
		"color": get_player_color(alias).to_html(false)
	})
	WebSocketServer.send_message(peer_id, response)
	player_connected.emit(alias, peer_id)
