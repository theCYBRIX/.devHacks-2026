class_name Car
extends CharacterBody2D

@export var max_forward_speed : float = 1000
@export var max_reverse_speed : float = 300
@export var max_acceleration  : float = 1000
@export var max_deceleration  : float = 600
@export var max_steering : float = deg_to_rad(180)
@export var min_turning_velocity : float = 25.0
@export var turning_loss_velocity : float = 125.0

@export var min_traction : float = 0.0
@export var max_traction : float = 0.8
@export var traction_recover_speed : float = 75
@export var traction_recover_time : float = 3

@export var enable_local_player : bool = true
@export var  _is_cop : bool = false : set = set_cop

@export var player_alias : String = ""
@export var player_color : Color = Color.WHITE : set = set_color

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var police_siren: AudioStreamPlayer = $PoliceSiren
@onready var engine_idle: AudioStreamPlayer = $EngineIdle
@onready var engine_high_rev: AudioStreamPlayer = $EngineHighRev
@onready var car_crashed: AudioStreamPlayer = $CarCrashed
@onready var car_tagged: AudioStreamPlayer = $CarTagged

const COP_CAR = preload("res://assets/cop_car.png")
const STREET_CAR = preload("res://assets/street_car.png")

const FORWARDS := Vector2.UP


var _max_fwd_spd := Vector2.UP * max_forward_speed
var _max_rvrs_spd := Vector2.UP * max_reverse_speed

var _speed : float = 0.0
var _traction : float = 0.8
var _since_traction_loss : float = 0
var _moving_forwards : bool = true


var acceleratior_input : float = 0
var steering_input : float = 0
var handbrake_pressed : float = 0
var siren_enabled : bool = false

var instance_id : int
static var instance_counter : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instance_id = instance_counter
	instance_counter += 1
	
	sprite_2d.texture = COP_CAR if is_cop() else STREET_CAR
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if enable_local_player and instance_id == 0:
		acceleratior_input = Input.get_axis("ui_down", "ui_up")
		steering_input = Input.get_axis("ui_left", "ui_right")
		handbrake_pressed = Input.is_action_pressed("handbrake")
	
	var current_forwards := FORWARDS.rotated(rotation)
	
	velocity += (FORWARDS * max_acceleration * acceleratior_input * delta).rotated(rotation)
	velocity *= 0.98
	
	_speed = velocity.length()
	_moving_forwards = velocity.dot(FORWARDS.rotated(rotation)) > 0
	
	
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
	
	if _moving_forwards:
		velocity = velocity.limit_length(max_forward_speed)
	else:
		velocity = velocity.limit_length(max_reverse_speed)
	
	
	if _speed > 25:
		if not engine_high_rev.playing:
			engine_high_rev.play()
			engine_idle.stop()
	else:
		if not engine_idle.playing:
			engine_idle.play()
			engine_high_rev.stop()
	
	var steering_amount : float 
	if _speed > min_turning_velocity:
		if _speed < turning_loss_velocity:
			steering_amount = steering_input * max_steering * inverse_lerp(min_turning_velocity, turning_loss_velocity, _speed) * delta
		else:
			steering_amount = steering_input * max_steering * delta
	rotation += steering_amount if _moving_forwards else -steering_amount
	
	#print(_speed)
	
	var collided = move_and_slide()
	
	if not collided: return
	
	var collision_count := get_slide_collision_count()
	var tagged_player : bool = false
	
	
	for i in range(collision_count):
		var details = get_slide_collision(i)
		var collider = details.get_collider()
		if collider is Car:
			velocity *= 0.5
			collider.velocity += velocity
			collider._speed = collider.velocity.length()
			if is_cop() and not collider.is_cop():
				collider.set_cop()
			elif not is_cop() and collider.is_cop():
				self.set_cop()
			else:
				continue
			tagged_player = true
		else:
			var normal := details.get_normal()
			var normal_velocity := velocity.project(normal)
			var normal_amount := normal_velocity.length()
			var deflection := (velocity - normal_velocity).normalized() * (normal_amount * 0.2)
			velocity = velocity - normal_velocity + deflection
			_traction = min_traction
	
	if tagged_player:
		car_tagged.play()
	elif _speed > 50 and not car_crashed.playing:
		car_crashed.play()
	
	_speed = velocity.length()


func set_color(col : Color) -> void:
	player_color = col
	if not is_cop():
		modulate = col


func set_cop(enabled := true) -> void:
	_is_cop = enabled
	if enabled:
		modulate = Color.WHITE
		if is_node_ready(): 
			sprite_2d.texture = COP_CAR
			if siren_enabled:
				police_siren.play()
	else:
		if is_node_ready():
			sprite_2d.texture = STREET_CAR
			police_siren.stop()
		modulate = player_color


func is_cop() -> bool:
	return _is_cop
