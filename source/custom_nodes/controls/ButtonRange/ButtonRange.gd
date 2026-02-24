@tool 
class_name ButtonRange extends Label

@export_category("Text")
@export var prefix: String:
	set(_v): prefix = _v; _set_value_text()
@export var suffix: String:
	set(_v): suffix = _v; _set_value_text()

var _value_str: String


@export_category("Value")
@export var min: float: ##Minimum value. only has effect if [param limit_min] is enabled.
	set(_v): min = _v; value = value 

@export var max: float: ##Max value, only has effect if [param limit_max] is enabled.
	set(_v): max = _v; value = value

@export var limit_min: bool
@export var limit_max: bool
@export var value: float: set = set_value
@export var step: float = 0.1: ##The value that will be added when the arrows are been pressed.
	set(val): step = val; notify_property_list_changed() 

@export var shift_step_mult: float = 2.0##When pressing [param KEY_SHIFT], the [param value] will be multiplicated for this value.
@export var int_value: bool: 
	set(_v): int_value = _v; update_value_text()

var _call_emit: bool = true

var line_edit: LineEditAutoUnfocus = LineEditAutoUnfocus.new()
var button_up: Button = Button.new()
var button_down: Button = Button.new()

signal value_changed(value: float) ##Called when the value changes.
signal value_added(value: float) ##Called when the value changes, returns the value added
func _init() -> void: 
	custom_minimum_size.y = 40
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line_edit.name = &"LineEdit"
	line_edit.size = Vector2(88,custom_minimum_size.y)
	add_child(line_edit,false,Node.INTERNAL_MODE_FRONT); 
	
	button_up.name = &"ButtonUp"
	button_up.text = 'v'
	button_up.size = Vector2(line_edit.size.y,line_edit.size.y)
	button_up.pivot_offset = button_up.size/2.0
	button_up.rotation_degrees = 180.0
	button_up.focus_mode = Control.FOCUS_NONE
	add_child(button_up, Node.INTERNAL_MODE_FRONT);
	
	button_down.name = &"ButtonDown"
	button_down.size = Vector2(line_edit.size.y,line_edit.size.y)
	button_down.text = 'v'
	button_down.focus_mode = Control.FOCUS_NONE
	add_child(button_down, Node.INTERNAL_MODE_FRONT)

func _ready(): 
	line_edit.text_changed.connect(_on_value_text_changed)
	line_edit.text_submitted.connect(_on_value_text_submitted)
	button_up.button_down.connect(addValue)
	button_down.button_down.connect(subValue)
	minimum_size_changed.connect(_update_nodes_position.call_deferred)
	update_value_text()
	_update_nodes_position()

#region Value Methods
func addValue() -> void: 
	var _r_step = ceilf(step) if int_value else step
	value += _r_step*shift_step_mult if Input.is_key_pressed(KEY_SHIFT) else _r_step

func subValue() -> void: 
	var _r_step = ceilf(step) if int_value else step
	value -= _r_step*shift_step_mult if Input.is_key_pressed(KEY_SHIFT) else _r_step

func set_value_no_signal(_value: float):
	_call_emit = false; value = _value; _call_emit = true

func set_value(_value: float):
	if limit_min: _value = max(_value,min)
	if limit_max: _value = min(_value,max)
	
	var emit: bool = _call_emit and value != _value
	var difference: float = _value - value
	value = snappedf(_value,0.0001)
	if !line_edit.is_editing(): update_value_text()
	if !emit: return
	value_changed.emit(_value)
	value_added.emit(difference)

func _on_value_text_changed(new_text: String) -> void: set_value_no_signal(new_text.to_float()); 
func _on_value_text_submitted(_t: String): line_edit.release_focus(); update_value_text()
#endregion


func _draw() -> void: _update_nodes_position()

func _update_nodes_position():
	var width: float = get_minimum_size().x + 4
	line_edit.position.x = width + 1
	button_up.position.x = line_edit.position.x + line_edit.size.x + 7
	button_down.position.x = button_up.position.x + button_up.size.x + 7
	custom_minimum_size.x = button_down.position.x + button_down.size.x

func update_value_text()  -> void:
	if !line_edit: return
	var value_int = int(value)
	if int_value or value_int == value: _value_str = String.num_int64(value_int)
	else: _value_str = String.num(value)
	_set_value_text()

func _set_value_text() -> void: if line_edit: line_edit.text = prefix+_value_str+suffix
