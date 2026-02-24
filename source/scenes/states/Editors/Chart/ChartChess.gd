@tool
extends Chess
const CHESS_SIZE = 30.0

@export var mustPress: bool
@export var gfSection: bool
@export var event_chess: bool

signal gui_input_chess(event: InputEvent, chess: Chess)
func _ready() -> void: 
	super(); 
	if !Engine.is_editor_hint(): Conductor.section_hit_once.connect(_update_chess_chart_size)
	_update_chess_chart_size()

func _update_chess_chart_size():
	var beats_sub: int = 4.0 - Conductor.get_section_data(Conductor.section).get(&"section_beats",4.0)
	position.y = (beats_sub * 16.0) * CHESS_SIZE
	size.y = CHESS_SIZE * (16.0 - (beats_sub) + 16.0)

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"rect_size": property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR

func _gui_input(event: InputEvent) -> void: gui_input_chess.emit(event,self)
