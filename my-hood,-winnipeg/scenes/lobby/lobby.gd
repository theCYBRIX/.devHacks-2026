extends Control


signal list_updated


const GAME_SCREEN = preload("uid://ckpuqcsc0cgi6")
const PLAYER_ENTRY = preload("uid://cgg8p5yetahvu")


@onready var player_list: VFlowContainer = $HBoxContainer/MarginContainer2/PanelContainer/MarginContainer/ScrollContainer/PlayerList


var _player_items : Dictionary[String, PlayerEntry] = {}
var _list_updating : bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerManager.player_connected.connect(_on_player_connected)
	PlayerManager.player_disconnected.connect(_on_player_disconnected)
	_refresh_player_list()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_player_connected(player : PlayerProps) -> void:
	var entry := _create_player_entry(player)
	
	if not is_node_ready():
		return
	
	player_list.add_child(entry, true, InternalMode.INTERNAL_MODE_FRONT)
	player_list.move_child(entry, player.player_num - 1)


func _on_player_disconnected(player : PlayerProps) -> void:
	if _list_updating:
		await list_updated
	
	if _player_items.has(player.alias):
		var list_entry := _player_items[player.alias]
		if list_entry and is_instance_valid(list_entry):
			list_entry.queue_free()
		_player_items.erase(player.alias)


func _refresh_player_list() -> void:
	_list_updating = true
	for player in PlayerManager.get_players():
		if not _player_items.has(player.alias):
			_create_player_entry(player)
	
	var items := _player_items.values()
	for child in player_list.get_children(true):
		if child is PlayerEntry and child in items:
			player_list.remove_child(child)
	
	var names_by_num : Dictionary[int, String] = {}
	for alias in _player_items.keys():
		names_by_num[PlayerManager.get_player_number(alias)] = alias
	
	var sorted_numbers : Array[int] = names_by_num.keys()
	sorted_numbers.sort()
	
	for number in sorted_numbers:
		var alias : String = names_by_num[number]
		var child : PlayerEntry = _player_items[alias]
		child.name = str(number)
		add_child(child, true)
		move_child(child, number - 1)
	
	_list_updating = false
	list_updated.emit()


func _create_player_entry(player : PlayerProps) -> PlayerEntry:
	var entry : PlayerEntry = PLAYER_ENTRY.instantiate()
	entry.name = str(player.player_num)
	entry.alias = player.alias
	entry.color = player.color
	_player_items[player.alias] = entry
	return entry


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(GAME_SCREEN)
