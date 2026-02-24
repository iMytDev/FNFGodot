class_name LineEditAutoUnfocus extends LineEdit
##A [LineEdit] class that release the focus when clicking outside.

@export var unfocus_on_submit: bool = true:
	set(val):
		if unfocus_on_submit == val: return
		unfocus_on_submit = val; _connect_submit()

func _connect_submit():
	if unfocus_on_submit: text_submitted.connect(_release_focus)
	else: text_submitted.disconnect(_release_focus)

func _release_focus(_t): release_focus()

func _init() -> void: _connect_submit()
func _ready() -> void:
	focus_entered.connect(set_process_input.bind(true))
	focus_exited.connect(set_process_input.bind(false))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and !get_global_rect().has_point(event.position): release_focus()
