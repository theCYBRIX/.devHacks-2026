extends Control


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func play_countdown() -> void:
	animation_player.play("countdown")
