extends Node


@export var car : Car
@export var idle_audio: AudioStream : set = set_idle_audio
@export var high_audio: AudioStream : set = set_high_audio
@export var sound_change_thresh : float = 50
@export var max_pitch : float = 2
@export var min_pitch : float = 0.60


@onready var idle_audio_player: AudioStreamPlayer = $IdleAudioPlayer
@onready var high_audio_player: AudioStreamPlayer = $HighAudioPlayer
@onready var audio_transitioner: AnimationPlayer = $AudioTransitioner


enum RpmState {
	IDLE,
	HIGH
}

# TODO: Add spooling down before idle if car slows down too fast

var _rpm_state : RpmState = RpmState.IDLE

func _ready() -> void:
	if idle_audio: idle_audio_player.stream = idle_audio
	if high_audio: high_audio_player.stream = high_audio


func _process(delta: float) -> void:
	
	if car._speed - sound_change_thresh < 0:
		if not idle_audio_player.playing:
			match _rpm_state:
				RpmState.IDLE:
					idle_audio_player.play()
				RpmState.HIGH:
					audio_transitioner.play("fade_to_idle")
					_rpm_state = RpmState.IDLE
	else:
		if not high_audio_player.playing:
			
			match _rpm_state:
				RpmState.IDLE:
					audio_transitioner.play("fade_to_high")
					_rpm_state = RpmState.HIGH
				RpmState.HIGH:
					high_audio_player.play()
		
		high_audio_player.pitch_scale = lerpf(min_pitch, max_pitch, inverse_lerp(0, car.max_forward_speed, car._speed))


func set_idle_audio(stream : AudioStream) -> void:
	idle_audio = stream
	if is_node_ready():
		idle_audio_player.stream = idle_audio


func set_high_audio(stream : AudioStream) -> void:
	high_audio = stream
	if is_node_ready():
		high_audio_player.stream = high_audio
