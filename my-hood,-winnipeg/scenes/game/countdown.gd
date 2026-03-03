extends Control

## Called/emitted from within the AnimationPlayer
signal go

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func play_countdown() -> Signal:
	animation_player.play("countdown")
	return go
