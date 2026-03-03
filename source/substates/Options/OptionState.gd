extends Node

func _ready() -> void:
	var bg = Sprite2D.new()
	bg.texture = Paths.texture("menuDesat")
	add_child(bg)
