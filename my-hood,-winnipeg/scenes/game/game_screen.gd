extends Node


@onready var car_manager: CarManager = $CarManager
@onready var countdown: Control = $CanvasLayer/Countdown
@onready var background: AudioStreamPlayer = $Background
@onready var start_label: Label = $CanvasLayer/StartLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	car_manager.block_inputs = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()


func _on_start_pressed() -> void:
	start_label.hide()
	await countdown.play_countdown()
	background.play()
	car_manager.block_inputs = false


func _repeat_music() -> void:
	background.play()


func _on_background_finished() -> void:
	background.play()
