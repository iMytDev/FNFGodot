extends LineEdit
##A [LineEdit] class that release the focus when clicking outside.

func _ready() -> void:
	focus_entered.connect(set_process_input.bind(true))
	focus_exited.connect(set_process_input.bind(false))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and !get_global_rect().has_point(event.position): release_focus()
