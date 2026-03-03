extends Node


signal player_connected(player : PlayerProps)
signal player_disconnected(player : PlayerProps)
signal player_input(player : PlayerProps, inputs : Dictionary)
signal player_numbers_changed


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

@export var player_limit : int = 8

var _player_props : Array[PlayerProps] = []
var _player_by_alias : Dictionary[String, PlayerProps] = {}
var _player_by_peer_id : Dictionary[int, PlayerProps] = {}

var _available_colors : Array[Color] = PLAYER_COLORS.duplicate()
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
			_on_player_timed_out(player)
		else:
			_timeouts[player] = time_elapsed
			#print("%s: %d" % [player, time_elapsed])


func get_player_color(alias : String) -> Color:
	if not _player_by_alias.has(alias): return 0x000000
	var player : PlayerProps = _player_by_alias.get(alias)
	return player.color

func get_player_number(alias : String) -> int:
	if not _player_by_alias.has(alias): return -1
	var player : PlayerProps = _player_by_alias.get(alias)
	return player.player_num


func get_player_aliases() -> Array[String]:
	var aliases : Array[String] = []
	aliases.assign(_player_by_alias.keys())
	return aliases


func get_players() -> Array[PlayerProps]:
	return _player_props.duplicate()


func get_player_count() -> int:
	return _player_props.size()


func _on_peer_message(id : int, message : String) -> void:
	var inputs = JSON.parse_string(message)
	#print("message received: " +  message)
	if not inputs:
		print("ERROR: Failed to parse packet from peer %d:\n\t%s" % [id, message])
		return
	
	if inputs.has("name"):
		_handle_alias_request(id, inputs)
	else:
		var player = _player_by_peer_id.get(id)
		if not player: return
		player_input.emit(player, inputs.get("joystickData", {}))


func _add_player(peer_id : int, alias : String) -> void:
	
	var player := _register_player(peer_id, alias)
	
	player_connected.emit(player)
	print("Player %s (%d) connected." % [player.alias, player.player_num])


func _remove_player(alias : String) -> void:
	if not _player_by_alias.has(alias):
		printerr('Attempted to unregister non-existent player "%s"' % alias)
		return
	
	var props : PlayerProps = _player_by_alias.get(alias)
	_unregister_player(props)
	
	if PLAYER_COLORS.has(props.color): _available_colors.append(props.color)
	
	player_disconnected.emit(props)


func _get_random_color() -> Color:
	return Color(100 + randf_range(0, 155), 100 + randf_range(0, 155), 100 + randf_range(0, 155))


func _register_player(peer_id : int, alias : String) -> PlayerProps:
	var player_col : Color = _available_colors.pop_back() if not _available_colors.is_empty() else _get_random_color()
	var player_num = get_player_count() + 1
	var props := PlayerProps.new(
		peer_id,
		alias,
		player_col,
		player_num
	)
	
	_player_props.append(props)
	_player_by_alias[props.alias] = props
	_player_by_peer_id[props.peer_id] = props
	
	return props


func _unregister_player(props : PlayerProps) -> void:
	_player_by_alias.erase(props.alias)
	_player_by_peer_id.erase(props.peer_id)
	_player_props.erase(props)
	_update_player_numbers()


func _update_player_numbers() -> void:
	var numbers_changed := false
	
	for idx : int in range(_player_props.size()):
		var player := _player_props[idx]
		var num = idx + 1
		if player.player_num != num:
			player.player_num = num
			numbers_changed = true
	
	if numbers_changed:
		player_numbers_changed.emit()


func _on_peer_disconnected(peer_id : int) -> void:
	if not _player_by_peer_id.has(peer_id): return
	
	var player : PlayerProps = _player_by_peer_id.get(peer_id)
	_player_by_peer_id.erase(peer_id)
	_start_player_timeout(player)
	
	print("Player %s (%d) lost connection." % [player.alias, player.player_num])
	


func _on_player_reconnected(peer_id : int, alias : String) -> void:
	var player : PlayerProps = _player_by_alias[alias]
	_stop_player_timeout(player)
	_player_by_peer_id[peer_id] = player
	print("Player %s (%d) reconnected." % [alias, get_player_number(alias)])


func _start_player_timeout(player : PlayerProps) -> void:
	_timeouts[player.alias] = 0.0
	set_process(true)


func _stop_player_timeout(player : PlayerProps) -> void:
	_timeouts.erase(player.alias)
	if _timeouts.is_empty():
		set_process(false)


func _on_player_timed_out(alias : String) -> void:
	_remove_player(alias)
	_timeouts.erase(alias)
	print("Player %s timed out." % alias)


func _handle_alias_request(peer_id : int, data : Dictionary) -> void:
	var response : String
	
	if not data or not data.has("name"):
		response = JSON.stringify({
				"accepted": false,
				"reason": "Bad request"
			})
		printerr("Invalid alias request by peer %d:\n%s" % [peer_id, JSON.stringify(data)])
	else:
		var alias = data.name
		var is_reconnect := _timeouts.has(alias)
		
		if is_reconnect:
			_on_player_reconnected(peer_id, alias)
			response = JSON.stringify({
				"accepted": true,
				"color": get_player_color(alias).to_html(false)
			})
		
		elif _player_by_alias.has(alias):
			response = JSON.stringify({
				"accepted": false,
				"reason" : "Name is taken"
			})
		
		elif get_player_count() >= player_limit:
			response = JSON.stringify({
				"accepted": false,
				"reason" : "Player limit reached"
			})
			
		else:
			_add_player(peer_id, alias)
			response = JSON.stringify({
				"accepted": true,
				"color": get_player_color(alias).to_html(false)
			})
			
	
	WebSocketServer.send_message(peer_id, response)
