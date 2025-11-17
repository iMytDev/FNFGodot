@tool
extends Chess
const NoteChart = preload("uid://dxl7cofy02rr5")
var notes: Node2D = Node2D.new()

var _beat_lines: Array[SolidSprite]
func _ready() -> void: add_child(notes); _create_beat_lines()

func _draw() -> void: super._draw(); _create_beat_lines()


func _update_beat_lines_size() -> void:
	var index: int = _beat_lines.size()
	while index: index -= 1; _beat_lines[index].size = Vector2(width,3)
func _update_beat_lines_position() -> void:
	var index: int = _beat_lines.size()
	while index:
		index -= 1
		_beat_lines[index].position.y = rect_size.y*(index+1)*4
func _create_beat_lines():
	var beats = int(length/4)
	while _beat_lines.size() > beats: _beat_lines.pop_back().queue_free()
	while _beat_lines.size() < beats:
		var line = SolidSprite.new()
		line.modulate = Color.RED
		add_child(line)
		_beat_lines.append(line)
	_update_beat_lines_size()
	_update_beat_lines_position()
	
