class_name PlayerProps
extends RefCounted


var peer_id : int
var alias : String
var color : Color
var player_num : int


@warning_ignore("shadowed_variable")
func _init(peer_id : int, alias : String, color : Color, player_num) -> void:
	self.peer_id = peer_id
	self.alias = alias
	self.color = color
	self.player_num = player_num
