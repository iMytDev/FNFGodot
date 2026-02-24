extends PopupPanel
const max_icon_width = 35

var events_json: Dictionary

@onready var folder_general_container = $ScrollContainer/Container/General/VBoxContainer
@onready var folder_2d = $"ScrollContainer/Container/2D"
@onready var folder_2d_container = folder_2d.get_node(^"VBoxContainer")
@onready var folder_3d = $"ScrollContainer/Container/3D"
@onready var folder_3d_container = folder_3d.get_node(^"VBoxContainer")

signal on_event_selected(event_name: Button)
func _ready() -> void: 
	visibility_changed.connect(func():
		if get_parent(): position = get_parent().global_position
	)
	add_theme_constant_override(&"icon_max_width",max_icon_width)
	_refresh(); 


func _refresh():
	events_json.clear()
	_load_separated_events("custom_events/2d",folder_2d_container)
	_load_separated_events("custom_events/3d",folder_3d_container)
	_load_events_from("custom_events",folder_general_container)

func _load_separated_events(dir: String, container: Container):
	_load_events_from(dir,container)
	var col = container.get_parent().get(&"theme_override_colors/font_color")
	for i in container.get_children(): 
		i.set(&"theme_override_colors/font_color",col)
		i.set(&"theme_override_colors/font_hover_color",col*1.5)
	
func _load_events_from(dir: String, node: Node):
	for i in node.get_children(): i.queue_free()
	for i in PathsDir.get_files_at(dir,true,"json",true):
		node.add_child(_create_button(i))

func _on_event_selected(button: Button): 
	on_event_selected.emit(button); hide()

func _create_button(event_path: String) -> Button:
	var button = Button.new()
	var event_name = event_path.get_file().get_basename()
	var event_data = Paths.load_json_absolute(event_path)
	var event_icon = event_data.get("icon")
	button.custom_minimum_size.y = 35
	button.text = event_name
	button.name = event_name
	
	button.set_meta(&"event_data", event_data)
	button.button_down.connect(_on_event_selected.bind(button))
	if event_icon:
		event_data.icon_texture = Paths.texture(event_icon)
		button.icon = event_data.icon_texture
		button.add_theme_constant_override(&"icon_max_width",max_icon_width)
	return button
