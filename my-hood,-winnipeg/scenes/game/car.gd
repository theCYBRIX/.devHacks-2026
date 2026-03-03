class_name Car
extends CharacterBody2D

@export var local_controlled : bool = false

@export var max_forward_speed : float = 400
@export var max_reverse_speed : float = 250
@export var max_acceleration  : float = 200
@export var max_deceleration  : float = 125
@export var max_steering : float = deg_to_rad(180)
@export var min_turning_velocity : float = 15.0
@export var turning_loss_velocity : float = 125.0

@export var min_traction : float = 0.0
@export var max_traction : float = 0.8
@export var traction_recover_speed : float = 75
@export var traction_recover_time : float = 3

@export var enable_local_player : bool = true
@export var  _is_cop : bool = false : set = set_cop

@export var player_alias : String = ""
@export var color : Color = Color.WHITE : set = set_color

@onready var sprite: Sprite2D = $Sprite
@onready var car_crashed: AudioStreamPlayer = $CarCrashed
@onready var wall_crashed: AudioStreamPlayer = $WallCrashed
@onready var car_tagged: AudioStreamPlayer = $CarTagged
@onready var car_type_component: Node2D = $StreetCarComponent

const COP_SPRITE = preload("res://assets/cop_car.png")
const STREET_SPRITE = preload("res://assets/street_car.png")

const COP_CAR_COMPONENT = preload("uid://b33ihb1f0gpud")
const STREET_CAR_COMPONENT = preload("uid://bvp0jrhjd7ric")


const FORWARDS := Vector2.UP


var _speed : float = 0.0
var _traction : float = 0.8
var _since_traction_loss : float = 0
var _moving_forwards : bool = true
var _crashing : bool = false
var _just_crashed : bool = false


var acceleratior_input : float = 0
var steering_input : float = 0
var handbrake_pressed : float = 0
var siren_enabled : bool = false

var instance_id : int
static var instance_counter : int = 0

func _ready() -> void:
	instance_id = instance_counter
	instance_counter += 1
	
	if is_cop():
		_switch_components_to_cop()
	else:
		_switch_components_to_street()


func _physics_process(delta: float) -> void:
	
	if local_controlled:
		acceleratior_input = Input.get_axis("decelerate", "accelerate")
		steering_input = Input.get_axis("turn_left", "turn_right")
		handbrake_pressed = Input.is_action_pressed("handbrake")
	
	var current_forwards := FORWARDS.rotated(rotation)
	
	if is_zero_approx(acceleratior_input) or not is_zero_approx(steering_input): velocity *= 0.99
	velocity += current_forwards * max_acceleration * acceleratior_input * delta
	
	
	#if _speed > traction_loss_speed:
		#var traction = lerpf(min_traction, max_traction, 1 - (min(_speed, min_traction_speed) - traction_loss_speed) / (min_traction_speed - traction_loss_speed))
		#velocity -= velocity.project(FORWARDS.rotated(rotation + PI / 2)) * traction
	#else:
	
	if handbrake_pressed:
		_traction = min_traction
		_since_traction_loss = 0
	elif not is_equal_approx(_traction, max_traction):# and _speed > traction_recover_speed:
		_since_traction_loss = min(_since_traction_loss + delta, traction_recover_time)
		_traction = smoothstep(min_traction, max_traction, _since_traction_loss / traction_recover_time)
	else:
		_traction = max_traction
	
	velocity -= velocity.project(FORWARDS.rotated(rotation + PI / 2)) * _traction
	
	_moving_forwards = velocity.dot(current_forwards) > 0
	velocity = velocity.limit_length(max_forward_speed if _moving_forwards else max_reverse_speed)
	_speed = velocity.length()
	
	
	#if _speed > 25:
		#if not engine_high_rev.playing:
			#engine_high_rev.play()
			#engine_idle.stop()
	#else:
		#if not engine_idle.playing:
			#engine_idle.play()
			#engine_high_rev.stop()
	
	var steering_amount : float 
	if _speed > min_turning_velocity:
		if _speed < turning_loss_velocity:
			steering_amount = steering_input * max_steering * inverse_lerp(min_turning_velocity, turning_loss_velocity, _speed) * delta
		else:
			steering_amount = steering_input * max_steering * delta
	rotation += steering_amount if _moving_forwards else -steering_amount
	
	#print(_speed)
	var was_crashing := _crashing
	_crashing = move_and_slide()
	
	_just_crashed = _crashing and not was_crashing
	
	if not _crashing: return
	
	var collision_count := get_slide_collision_count()
	var tagged_player : bool = false
	var crashed_car : bool = false
	var crashed_wall : bool = false
	
	
	for i in range(collision_count):
		var details = get_slide_collision(i)
		var collider = details.get_collider()
		if collider is Car:
			crashed_car = true
			velocity *= 0.5
			_traction = min_traction
			collider.velocity += velocity
			collider._speed = collider.velocity.length()
			collider._traction = min_traction
			if is_cop() and not collider.is_cop():
				collider.set_cop()
			elif not is_cop() and collider.is_cop():
				self.set_cop()
			else:
				continue
			tagged_player = true
		else:
			crashed_wall = true
			var normal := details.get_normal()
			var normal_velocity := velocity.project(normal)
			var normal_amount := normal_velocity.length()
			var deflection := (velocity - normal_velocity).normalized() * (normal_amount * 0.2)
			velocity = velocity - normal_velocity + deflection
			_traction = min_traction
	
	if tagged_player:
		car_tagged.play()
	if _just_crashed and _speed > 50 and crashed_car:
		car_crashed.play()
	if _just_crashed and _speed > 50 and not wall_crashed.playing:
		wall_crashed.play()
	
	_speed = velocity.length()


func set_color(col : Color) -> void:
	color = col
	if not is_cop():
		modulate = col


func set_cop(enabled := true) -> void:
	_is_cop = enabled
	if enabled:
		modulate = Color.WHITE
		if is_node_ready(): 
			_switch_components_to_cop()
	else:
		if is_node_ready():
			_switch_components_to_street()
		modulate = color


func is_cop() -> bool:
	return _is_cop


func _switch_components_to_cop() -> Node:
	sprite.texture = COP_SPRITE
	return _switch_type_component(COP_CAR_COMPONENT)


func _switch_components_to_street() -> Node:
	sprite.texture = STREET_SPRITE
	return _switch_type_component(STREET_CAR_COMPONENT)


func _switch_type_component(to : PackedScene) -> Node:
	if not is_node_ready():
		printerr("Unable to switch type: Node is not ready.")
		return
	if car_type_component and is_instance_valid(car_type_component): car_type_component.queue_free()
	car_type_component = to.instantiate()
	add_child(car_type_component, false, Node.INTERNAL_MODE_FRONT)
	car_type_component.owner = self
	return car_type_component
