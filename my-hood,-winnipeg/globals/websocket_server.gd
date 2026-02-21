extends Node

signal peer_connected(peer_id : int)
signal peer_message(peer_id : int, msg : String)
signal peer_disconnected(peer_id : int)
signal player_registered(peer_id : int, alias : String)

const SERVER_PORT := 3050
const SOCKET_CLOSE_TIMEOUT_SEC : float = 10


var _tcp_server : TCPServer
var _peers : Dictionary[int, WebSocketPeer] = {}


var _available_ids : Array[int] = []
var _id_counter : int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	while _tcp_server.is_connection_available():
		var peer = WebSocketPeer.new()
		peer.accept_stream(_tcp_server.take_connection())
		var peer_id : int
		
		if _available_ids.is_empty():
			_id_counter += 1
			peer_id = _id_counter
		else:
			peer_id = _available_ids.pop_back()
		
		peer_connected.emit(peer_id)
	
	var closed_peers : Array[int] = []
	for peer_id : int in _peers.keys():
		var peer : WebSocketPeer = _peers[peer_id]
		
		peer.poll()
		
		var ready_state := peer.get_ready_state()
		match ready_state:
			WebSocketPeer.STATE_OPEN:
				while peer.get_available_packet_count() > 0:
					var packet := peer.get_packet()
					if peer.was_string_packet():
						peer_message.emit(peer_id, packet.get_string_from_utf8())
					else:
						print("ERROR: Peer %d sent invalid packet." % _peers.find_key(peer))
			
			WebSocketPeer.STATE_CLOSED:
				closed_peers.append(peer_id)
	
	for peer_id : int in closed_peers:
		_peers.erase(peer_id)
		peer_disconnected.emit(peer_id)


func start() -> void:
	if _tcp_server and is_instance_valid(_tcp_server):
		await shutdown()
	
	_tcp_server = TCPServer.new()
	_tcp_server.listen(SERVER_PORT)
	print("Server started on port %d" % SERVER_PORT)


func shutdown(code : int = 1001, reason : String = "Going Away") -> void:
	var queued := is_queued_for_deletion()
	if queued: cancel_free() 
	
	if _tcp_server and is_instance_valid(_tcp_server):
		_tcp_server.stop()
		for peer : WebSocketPeer in _peers.values():
			peer.close(code, reason)
		
		var initial_time := Time.get_ticks_msec()
		
		var clean_closures : Array[WebSocketPeer] = []
		while not _peers.is_empty() and ((Time.get_ticks_msec() - initial_time) / 1000) < SOCKET_CLOSE_TIMEOUT_SEC:
			for peer : WebSocketPeer in _peers.values():
				peer.poll()
				
				if peer.get_ready_state() == WebSocketPeer.STATE_CLOSED:
					clean_closures.append(peer)
			
			for peer : WebSocketPeer in clean_closures:
				_peers.erase(_peers.find_key(peer))
		
		_tcp_server.unreference()
		
		await get_tree().create_timer(0.25).timeout
		print("Server shutdown...")
	
	if queued: queue_free()


func send_message(peer_id : int, msg : String) -> void:
	var peer : WebSocketPeer = _peers.get(peer_id)
	if not peer: return
	peer.send_text(msg)


func get_peer_count() -> int:
	return _peers.size()


func is_active() -> bool:
	return _tcp_server.is_listening() and not _peers.is_empty()
