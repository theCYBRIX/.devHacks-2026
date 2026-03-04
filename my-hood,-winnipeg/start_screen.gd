extends Control


const LOBBY = preload("uid://b3tnupk6o6oyb")


func _on_host_button_pressed() -> void:
	WebSocketServer.start()
	get_tree().change_scene_to_packed(LOBBY)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
