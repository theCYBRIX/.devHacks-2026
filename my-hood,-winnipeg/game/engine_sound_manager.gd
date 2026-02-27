extends Node


@export var car : Car
@export var engine_audio: AudioStream : set = set_engine_audio
@export var max_pitch : float = 2
@export var min_pitch : float = 0.60

@export var max_rpm : float = 9000
@export var idle_rpm : float = 1000
@export var rpm_climb_rate : float = 6000
@export var rpm_sink_rate : float = 4000


@onready var engine_audio_player: AudioStreamPlayer = $HighAudioPlayer
@onready var audio_transitioner: AnimationPlayer = $AudioTransitioner


var rpm = idle_rpm

# TODO: Add spooling down before idle if car slows down too fast

func _ready() -> void:
	if engine_audio: engine_audio_player.stream = engine_audio


func _process(delta: float) -> void:
	if not engine_audio_player.playing:
		engine_audio_player.play()
	
	#if Input.is_action_just_pressed("accelerate"):
		#rpm = lerpf(idle_rpm, max_rpm, absf(car.acceleratior_input))
	if car._crashing:
		var required_rpm : float = lerpf(idle_rpm, max_rpm, absf(car.acceleratior_input))
		
		if car._just_crashed:
			rpm = max(max(rpm / 2, lerpf(idle_rpm, max_rpm, car._speed / car.max_forward_speed)), idle_rpm)
		if required_rpm > rpm:
			rpm = min(rpm + rpm_climb_rate * delta, required_rpm)
		else:
			rpm = max(rpm - rpm_sink_rate * delta, required_rpm)
		
	else:
		var required_rpm : float
		var ignore_climb_rate : bool
		
		if car._traction < car.max_traction:
			required_rpm = lerpf(idle_rpm, max_rpm, lerpf(car._speed / car.max_forward_speed, abs(car.acceleratior_input), inverse_lerp(car.min_traction, car.max_traction, 1 - car._traction)))
			ignore_climb_rate = false
		else:
			required_rpm = lerpf(idle_rpm, max_rpm, car._speed / car.max_forward_speed)
			ignore_climb_rate = true
		
		if required_rpm > rpm:
			rpm = required_rpm if ignore_climb_rate else min(rpm + rpm_climb_rate * delta, max_rpm)
		else:
			rpm = max(max(rpm - rpm_climb_rate * delta, required_rpm), required_rpm)
	
	
	engine_audio_player.pitch_scale = lerpf(min_pitch, max_pitch, inverse_lerp(idle_rpm, max_rpm, rpm))


func set_engine_audio(stream : AudioStream) -> void:
	engine_audio = stream
	if is_node_ready():
		engine_audio_player.stream = engine_audio
