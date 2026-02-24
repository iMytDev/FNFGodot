extends Panel

var container = VBoxContainer.new()

var title: String = 'Variable':
	set(val): title = val; _update_text()

var _title_node: Label = Label.new()
var default_button: Control

var type_button = MenuButton.new()
var type_popup = type_button.get_popup()

var data_type: EventValueType
var type: String

func _update_text(): _title_node.text = "Name: "+title

func _init(data: EventValueType = null) -> void:
	add_child(container)
	container.position.y = 5
	container.minimum_size_changed.connect(func(): 
		custom_minimum_size = container.get_minimum_size() + Vector2(0.0,15.0)
	)
	self_modulate = Color.BLACK
	
	_title_node.custom_minimum_size.y = 20
	container.add_child(_title_node)
	_update_text()
	
	add_theme_constant_override("separation",15)
	
	var type_title = Label.new()
	type_title.text = "Type: "
	type_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(type_title)
	
	type_button.position.x = type_title.get_minimum_size().x
	type_button.size = Vector2(80,30)
	type_button.flat = false
	type_button.add_theme_constant_override("icon_max_width",16)
	type_popup.add_theme_constant_override("icon_max_width",16)
	type_title.add_child(type_button)
	type_title.custom_minimum_size.y = type_button.size.y
	
	
	type_popup.index_pressed.connect(_on_type_selected)
	var index: int = 0
	for i in EventValueType.event_value_types:
		type_popup.add_item(i)
		match i:
			&"EasingType": type_popup.set_item_icon(index,load("res://icons/EditBezier.svg"))
			&"Folder": type_popup.set_item_icon(index,load("res://icons/load.svg"))
			_: type_popup.set_item_icon(index,load("res://icons/"+i+".svg"))
		index += 1
	
	data_type = data
	type = data.type_string
	_update_type()

func _on_type_selected(i: int):
	type = type_popup.get_item_text(i)
	data_type.type_string = type
	_update_type()

func _update_type():
	type_button.text = data_type.type_string
	type_button.icon = load("res://icons/"+type+".svg")
	if default_button: default_button.queue_free()
	
	match data_type.type_string:
		&"EasingType":
			default_button = MenuButton.new()
			default_button.text = data_type.default
			var popup = default_button.get_popup()
			for t in TweenService.transitions:
				popup.add_separator(t)
				for e in TweenService.easings: popup.add_check_item(t+e)
		&"Folder": 
			default_button = _get_default_title()
			
			var edit = LineEdit.new()
			edit.position.x = default_button.get_minimum_size().x
			edit.size = Vector2(150,default_button.custom_minimum_size.y)
			edit.text_submitted.connect(func(i): data_type.folder = i)
			edit.text = data_type.folder
			default_button.add_child(edit)
		_:
			match data_type.type:
				TYPE_STRING,TYPE_STRING_NAME:
					default_button = _get_default_title()
					
					var edit = LineEdit.new()
					edit.position.x = default_button.get_minimum_size().x
					edit.size = Vector2(150,default_button.custom_minimum_size.y)
					edit.text = data_type.default
					edit.text_submitted.connect(_set_default_value)
					default_button.add_child(edit)
				TYPE_FLOAT,TYPE_INT:
					default_button = ButtonRange.new()
					default_button.text = "Default: "
					default_button.int_value = data_type.type == TYPE_INT
					default_button.value_changed.connect(_set_default_value)
					default_button.set_value_no_signal(data_type.default)
				TYPE_BOOL:
					default_button = _get_default_title()
					
					var box = CheckButton.new()
					box.position.x = default_button.get_minimum_size().x - 10
					box.size.y = default_button.custom_minimum_size.y
					
					box.toggled.connect(_set_default_value)
					default_button.add_child(box)
				
	if default_button: container.add_child(default_button)

func _get_default_title() -> Label:
	var title = Label.new()
	title.text = "Default: "
	title.custom_minimum_size.y = 30
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return title

func _set_default_value(value: Variant): data_type.default = value
