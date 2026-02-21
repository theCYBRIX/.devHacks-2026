extends Node2D

@onready var spawn_points: Node2D = $SpawnPoints

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_spawn_points() -> Array[Marker2D]:
	var points : Array[Marker2D] = []
	for node in spawn_points.get_childred():
		if node is Marker2D:
			points.append(node)
	return points
