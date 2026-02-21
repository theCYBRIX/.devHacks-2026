extends Node

@export var car_parent : Node
@export var map : Map


const CAR = preload("res://game/car.tscn")

var _player_cars : Dictionary[String, Car] = {}
var _spawn_locations : Array[Marker2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerManager.player_connected.connect(_on_player_connected)
	PlayerManager.player_disconnected.connect(_on_player_disconnected)
	PlayerManager.player_input.connect(_on_player_input)
	
	_spawn_locations = map.get_spawn_points()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_block_inputs(enabled : bool) -> void:
	get_tree().call_group("Cars", "set_process", enabled)


func _on_player_input(alias : String, input : Dictionary) -> void:
	var car : Car = _player_cars[alias]
	if not car: return
	car.acceleratior_input = input.get("accelerate", 0)
	car.steering_input = input.get("steering", 0)
	car.handbrake_pressed = not is_zero_approx(input.get("brake", 0))


func _on_player_connected(alias : String, _id : int) -> void:
	var car : Car = CAR.instantiate()
	car.player_alias = alias
	car.player_color = PlayerManager.get_player_color(alias)
	_player_cars[alias] = car
	car_parent.add_child(car)
	car.owner = car_parent
	
	var spawn := _spawn_locations[]
	
	car.position = spawn_location.position
	car.rotation = spawn_location.rotation


func _on_player_disconnected(alias : String, _id : int) -> void:
	var car : Car = _player_cars[alias]
	if car and is_instance_valid(car): car.queue_free()
	_player_cars.erase(alias)
