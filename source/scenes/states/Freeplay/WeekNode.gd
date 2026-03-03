extends Node2D
const Unselect = Color.DARK_GRAY; const Selected = Color.WHITE
static var week_index: Dictionary[StringName, int]

var index: int = 0: set = set_index
var cur_song: Node

signal on_song_selected(song: Node)
func _init() -> void: child_entered_tree.connect(
	func(i): 
		i.modulate = Unselect
		if !cur_song: cur_song = i
)

func hide_week() -> void: 
	visible = false; 
	process_mode = Node.PROCESS_MODE_DISABLED

func show_week() -> void:
	visible = true; 
	process_mode = Node.PROCESS_MODE_INHERIT
	position.y = 0.0
	set_index(week_index.get(name,0))

func _process(delta: float) -> void:
	if !cur_song: return
	position.y = lerpf(position.y,-cur_song.position.y + ScreenUtils.screenCenter.y,delta*15.0)

func set_index(i: int):
	FunkinGD.playSound('scrollMenu')
	if cur_song: cur_song.modulate = Unselect
	index = wrapi(i, 0, get_child_count())
	
	cur_song = get_child(index)
	on_song_selected.emit(cur_song)
	if cur_song: cur_song.modulate = Selected
	week_index[name] = index


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if !event.pressed: return
		match event.keycode:
			KEY_UP: 
				if get_child_count() > 1: index -= 5 if event.shift_pressed else 1;
			KEY_DOWN: 
				if get_child_count() > 1: index += 5 if event.shift_pressed else 1;
				
	elif event is InputEventMouseButton:
		if !event.pressed: return
		match event.button_index:
			4: index -= 1
			5: index += 1
