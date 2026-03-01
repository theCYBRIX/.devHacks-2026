extends Node2D


@onready var engine_sound_manager: EngineSoundManager = $EngineSoundManager
@onready var siren: AudioStreamPlayer = $Siren


func _ready() -> void:
	var parent := get_parent()
	if parent and parent is Car:
		engine_sound_manager.set_car(parent)
	siren.play()


func _on_siren_finished() -> void:
	siren.play()
