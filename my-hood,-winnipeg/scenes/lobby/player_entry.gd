@tool
class_name PlayerEntry
extends Control


@onready var label: Label = $HBoxContainer/Label
@onready var color_indicator: Control = $HBoxContainer/ColorIndicator
@onready var h_box_container: HBoxContainer = $HBoxContainer


@export var alias : String : set = set_alias
@export var color : Color : set = set_color
@export var character_limit : int = 10 : set = set_character_limit


func _ready() -> void:
	_update_alias_label()
	color_indicator.modulate = color


func set_alias(str : String) -> void:
	alias = str.strip_edges()
	_update_alias_label()


func set_color(col : Color) -> void:
	color = col
	if is_node_ready(): color_indicator.modulate = color


func set_character_limit(limit : int) -> void:
	character_limit = limit
	_update_alias_label()


func _update_alias_label() -> void:
	if not is_node_ready(): return
	if alias.length() > character_limit:
		label.text = alias.left(character_limit - 3).strip_edges() + "..."
	else:
		label.text = alias
	update_minimum_size()


func _get_minimum_size() -> Vector2:
	return h_box_container.get_combined_minimum_size() if is_node_ready() else Vector2.ZERO
