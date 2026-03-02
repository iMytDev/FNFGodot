extends Node2D
const UNSELECTED_COLOR = Color.DARK_GRAY
const SELECTED_COLOR = Color.WHITE

var options: Array[Node]
var option_node: Node
var option_index: int = 0: set = _set_option_index
var camera_limit_y = 500

signal scrolled(index: int, old_index: int)
func _ready() -> void: if options: _set_option_index(0)

func _set_option_index(index: int):
	if !options: option_index = 0; return
	if option_node: option_node.modulate = UNSELECTED_COLOR
	option_node = options[index]
	scrolled.emit(index,option_index)
	option_index = index
	option_node.modulate = SELECTED_COLOR

func _process(delta: float) -> void:
	position.y = lerpf(
		position.y,
		-camera_limit_y*(float(option_index)/options.size()) + (500*(1.0-scale.y)),
		10*delta
	) 
