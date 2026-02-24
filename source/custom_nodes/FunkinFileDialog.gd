@tool
class_name FunkinFileDialog extends FileDialog
@export var clear_after_hidded: bool:
	set(val):
		if val == clear_after_hidded: return
		if !is_node_ready(): return
		if val: canceled.connect(_on_canceled)
		else: canceled.disconnect(_on_canceled)
		clear_after_hidded = val
func _init() -> void:
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	access = FileDialog.ACCESS_FILESYSTEM
	current_dir = PathsStore.assetsPath
	

func _ready() -> void:
	if clear_after_hidded: canceled.connect(_on_canceled)

func disconnect_signal_methods(_signal: Signal): 
	for i in _signal.get_connections(): _signal.disconnect(i)

func _on_canceled() -> void:
	disconnect_signal_methods(file_selected)
	disconnect_signal_methods(files_selected)
	disconnect_signal_methods(dir_selected)
	clear_filters()
