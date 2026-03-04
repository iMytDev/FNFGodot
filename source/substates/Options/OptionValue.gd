extends FunkinText
const FunkinCheckBox = preload("uid://7ipxxo56l60m")
const NumberRange = preload("uid://7g33qugw2fc1")


var object: Object
var property: StringName
var options: Dictionary = {}
var value_type: int
var value: Node:
	set(val):
		if value: value.queue_free()
		value = val
		if val: add_child(val); _update_value_pos()

func _init(
	_name: StringName, 
	_object: Object,
	_property: StringName,
	_options: Dictionary = {},
	_visual: Object = null,
):
	super(_name)
	name = _name
	text = _name+": "
	object = _object
	property = _property
	options = _options
	value_type = typeof(_object.get(_property))
	_create_option_button()

func _update_value_pos():
	if !value: return
	value.position.x = width

func _create_option_button() -> void:
	match value_type:
		TYPE_BOOL:
			value = FunkinCheckBox.new()
			value.offset.y = 40
			value.scale = Vector2(0.8,0.8)
			value.value = object[property]
			value.toggled.connect(_set_object_value)
		TYPE_FLOAT,TYPE_INT:
			value = NumberRange.new()
			value.value = object[property]
			value.value_changed.connect(_set_object_value)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				if value_type == TYPE_BOOL: 
					value.value = !value.value
			KEY_LEFT:
				if value_type == TYPE_INT or value_type == TYPE_FLOAT:
					value.value -= value.step
			KEY_RIGHT:
				if value_type == TYPE_INT or value_type == TYPE_FLOAT:
					value.value += value.step
			
func _set_object_value(value: Variant):
	object[property] = value
