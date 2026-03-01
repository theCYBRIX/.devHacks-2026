extends Node


signal player_connected(alias : String, player_num : int)
signal player_disconnected(alias : String, player_num : int)
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
var _available_colors : Array[Color] = PLAYER_COLORS.duplicate()
var _player_numbers : Dictionary[String, int] = {}
var _available_numbers : Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
var _timeouts : Dictionary[String, float] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	WebSocketServer.peer_message.connect(_on_peer_message)
	WebSocketServer.peer_disconnected.connect(_on_peer_disconnected)


func _process(delta: float) -> void:
	if _timeouts.is_empty():
		set_process(false)
	
	for player in _timeouts.keys():
		var time_elapsed := _timeouts[player] + delta
		if time_elapsed > PLAYER_TIMEOUT_SEC:
			_unregister_player(player)
			_timeouts.erase(player)
			print("Player %s timed out." % player)
		else:
			_timeouts[player] = time_elapsed
			#print("%s: %d" % [player, time_elapsed])


func get_player_color(alias : String) -> Color:
	return _player_colors.get(alias)

func get_player_number(alias : String) -> int:
	return _player_numbers.get(alias)


func get_player_aliases() -> Array[String]:
	var aliases : Array[String] = []
	aliases.assign(_player_ids.keys())
	return aliases


func get_player_count() -> int:
	return _player_ids.size()


func _on_peer_message(id : int, message : String) -> void:
	var inputs = JSON.parse_string(message)
	#print("message received: " +  message)
	if not inputs:
		print("ERROR: Failed to parse packet from peer %d:\n\t%s" % [id, message])
		return
	
	if inputs.has("name"):
		_handle_alias_request(id, inputs)
	else:
		var alias = _player_aliases.get(id)
		if not alias: return
		player_input.emit(alias, inputs.get("joystickData", {}))


func _on_player_registered(id : int, alias : String) -> void:
	var is_reconnect := _timeouts.has(alias)
	_player_ids[alias] = id
	_player_aliases[id] = alias
	if is_reconnect:
		_timeouts.erase(alias)
		print("Player %s (%d) reconnected." % [alias, get_player_number(alias)])
	else:
		var player_col : Color = _available_colors.pop_back() if not _player_colors.is_empty() else get_random_color()
		_player_colors[alias] = player_col
		var player_number = _available_numbers.pop_front()
		_player_numbers[alias] = player_number
		player_connected.emit(alias, player_number)
		print("Player %s (%d) connected." % [alias, get_player_number(alias)])


func _on_peer_disconnected(id : int) -> void:
	if not _player_aliases.has(id): return
	var alias : String = _player_aliases.get(id)
	var player_num : int = _player_numbers.get(alias, -1)
	_player_aliases.erase(id)
	_timeouts[alias] = 0.0
	set_process(true)
	print("Player %s (%d) lost connection." % [alias, player_num])


func get_random_color() -> Color:
	return Color(100 + randf_range(0, 155), 100 + randf_range(0, 155), 100 + randf_range(0, 155))


func _handle_alias_request(peer_id : int, data : Dictionary) -> void:
	var alias = data.name
	var response : String
	if _player_ids.has(alias) and not _timeouts.has(alias):
		response = JSON.stringify({ "accepted": false })
		return
	
	_on_player_registered(peer_id, alias)
	response = JSON.stringify({
		"accepted": true,
		"color": get_player_color(alias).to_html(false)
	})
	WebSocketServer.send_message(peer_id, response)


func _unregister_player(alias : String) -> void:
	_player_ids.erase(alias)
	var player_col : Color = _player_colors[alias]
	_player_colors.erase(alias)
	var player_number = _player_numbers[alias]
	_player_numbers.erase(alias)
	_available_numbers.append(player_number)
	_available_numbers.sort()
	if PLAYER_COLORS.has(player_col): _available_colors.append(player_col)
	player_disconnected.emit(alias, player_number)
