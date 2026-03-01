extends Node

@export var max_rpm : float = 9000
@export var idle_rpm : float = 1000
@export var rpm_climb_rate : float = 6000
@export var rpm_sink_rate : float = 4000
@export var rpm_sound_change_thresh : float = 200
@export var max_pitch : float = 2
@export var min_pitch : float = 0.60


@onready var rpm_label: Label = $RpmLabel
@onready var idle_rpm_audio: AudioStreamPlayer = $IdleRpm
@onready var high_rpm_audio: AudioStreamPlayer = $HighRpm
@onready var audio_transitioner: AnimationPlayer = $AudioTransitioner


enum RpmState {
	IDLE,
	HIGH
}


var rpm : float = idle_rpm
var _rpm_state : RpmState = RpmState.IDLE


func _process(delta: float) -> void:
	if Input.is_action_pressed("accelerate"):
		rpm = minf(rpm + rpm_climb_rate * delta, max_rpm)
	else:
		rpm = maxf(rpm - rpm_sink_rate * delta, idle_rpm)
	
	rpm_label.text = "RPM: %.2d" % rpm
	
	if rpm - rpm_sound_change_thresh < idle_rpm:
		if not idle_rpm_audio.playing:
			match _rpm_state:
				RpmState.IDLE:
					idle_rpm_audio.play()
				RpmState.HIGH:
					audio_transitioner.play("fade_to_idle")
					_rpm_state = RpmState.IDLE
	else:
		if not high_rpm_audio.playing:
			
			match _rpm_state:
				RpmState.IDLE:
					audio_transitioner.play("fade_to_high")
					_rpm_state = RpmState.HIGH
				RpmState.HIGH:
					high_rpm_audio.play()
		
		high_rpm_audio.pitch_scale = lerpf(min_pitch, max_pitch, inverse_lerp(idle_rpm, max_rpm, rpm))
