extends Control

const PLAYER_ENTRY = preload("res://lobby/player_entry.tscn")

var _player_items = Dictionary[int, ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerManager.player_connected.connect()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_connected(alias : String, id : int) -> void:
	
