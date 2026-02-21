extends Control


@onready var label: Label = $HBoxContainer/Label
@onready var color_rect: ColorRect = $HBoxContainer/ColorRect


var alias : String : set = set_alias
var color : Color : set = set_color


func ready() -> void:
	label.text = alias
	color_rect.color = color


func set_alias(str : String) -> void:
	if is_node_ready(): label.text = alias
	alias = str


func set_color(col : Color) -> void:
	color = col
	if is_node_ready(): color_rect.color = color
