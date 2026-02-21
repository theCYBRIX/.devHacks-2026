extends Control


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func play_countdown() -> Signal:
	animation_player.play("countdown")
	return animation_player.animation_finished
