@tool
extends Control


@export var style_box : StyleBox : set = set_style_box


func _draw() -> void:
	if not style_box: return
	draw_style_box(style_box, get_rect())


func set_style_box(box : StyleBox) -> void:
	style_box = box
	queue_redraw()
