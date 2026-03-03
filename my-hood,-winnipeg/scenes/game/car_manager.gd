class_name CarManager
extends Node


@export var car_parent : Node
@export var map : Map


const CAR = preload("uid://2bjklh70l1ic")


var block_inputs : bool = false : set = set_block_inputs
var _player_cars : Array[Car] = []
var _spawn_locations : Array[Marker2D]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player_cars.resize(PlayerManager.get_player_count())
	_spawn_locations = await map.get_spawn_points()
	
	PlayerManager.player_connected.connect(_on_player_connected)
	PlayerManager.player_disconnected.connect(_on_player_disconnected)
	PlayerManager.player_numbers_changed.connect(_on_player_numbers_changed)
	PlayerManager.player_input.connect(_on_player_input)
	
	for player in PlayerManager.get_players():
		if not _player_cars[player.player_num - 1]:
			_spawn_player(player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_block_inputs(enabled : bool) -> void:
	block_inputs = enabled


func _on_player_input(player : PlayerProps, input : Dictionary) -> void:
	#print(alias + ": " + JSON.stringify(input))
	if block_inputs: return
	if player.player_num <= 0 or player.player_num > _player_cars.size():
		printerr("Received inputs from invalid player number: %d" % player.player_num)
		return
	var car : Car = _player_cars[player.player_num - 1]
	if not car: 
		printerr("Car for player %d is null." % player.player_num)
		return
		
	var prev_acc_inpt = car.acceleratior_input
	car.acceleratior_input = clampf(input.get("y", 0.0), -1, 1)
	car.steering_input = clampf(input.get("x", 0.0), -1, 1)
	car.handbrake_pressed = (prev_acc_inpt > 0 and car.acceleratior_input < 0)


func _on_player_numbers_changed() -> void:
	_player_cars.sort_custom(_sort_player_cars)


func _sort_player_cars(first : Car, second : Car) -> bool:
	var first_num : int = PlayerManager.get_player_number(first.player_alias)
	var second_num : int = PlayerManager.get_player_number(second.player_alias)
	
	return false if first_num == -1 else first_num < second_num



func _spawn_player(player : PlayerProps) -> Car:
	var car : Car = CAR.instantiate()
	car.player_alias = player.alias
	car.color = player.color
	if player.player_num == 1: car.set_cop()
	_player_cars[player.player_num - 1] = car
	car_parent.add_child(car)
	car.owner = car_parent
	
	var spawn := _spawn_locations[player.player_num - 1]
	
	car.position = spawn.position
	car.rotation = spawn.rotation
	car.velocity = Vector2.ZERO
	#car.set_process(false)
	
	print("%s (%d) -> spawned" % [player.alias, player.player_num])
	return car


func _on_player_connected(player : PlayerProps) -> void:
	var player_count := PlayerManager.get_player_count()
	if _player_cars.size() != player_count:
		_player_cars.resize(player_count)
	_spawn_player(player)


func _on_player_disconnected(player : PlayerProps) -> void:
	var car : Car = _player_cars[player.player_num - 1]
	_player_cars.erase(car)
	if car and is_instance_valid(car): car.queue_free()
