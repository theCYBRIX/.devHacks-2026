extends Node

@onready var countdown: Control = $CanvasLayer/Countdown
@onready var background: AudioStreamPlayer = $Background


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await countdown.play_countdown()
	background.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_block_car_inputs(enabled : bool) -> void:
	get_tree().call_group("Cars", "set_process", not enabled)


func _repeat_music() -> void:
	background.play()


func _on_background_finished() -> void:
	background.play()
