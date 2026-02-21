extends Node


@onready var countdown: Control = $CanvasLayer/Countdown


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	countdown.play_countdown()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_block_car_inputs(enabled : bool) -> void:
	get_tree().call_group("Cars", "set_process", not enabled)
