extends VBoxContainer

var center: float = 0.0
@onready var line: SolidNode2D = $Line
func _ready() -> void:
	Conductor.song_position_changed.connect(_update_scroll)
	resized.connect(_update_center)
	_update_center()

func _update_scroll():
	line.position.x = Conductor.step_float * get_meta("chess_size").x
	position.x = maxf(0.0,line.position.x - center)

func _update_center():
	center = size.x * 0.5 / get_meta("chess_size").x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		match event.keycode:
			KEY_SPACE:
				if Conductor.is_playing: Conductor.pauseSongs()
				else: Conductor.resumeSongs()
