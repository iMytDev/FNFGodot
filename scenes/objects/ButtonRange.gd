@tool extends Label
#region Text Variables
@export_category("Text")
@export var prefix: String:
	set(_v): prefix = _v; _set_value_text()
@export var suffix: String:
	set(_v): suffix = _v; _set_value_text()

var _value_str: String
#endregion

#region Value Variables
@export_category("Value")
@export var min: float: ##Minimum value. only has effect if [param limit_min] is enabled.
	set(_v): min = _v; value = value 

@export var max: float: ##Max value, only has effect if [param limit_max] is enabled.
	set(_v): max = _v; value = value

@export var limit_min: bool
@export var limit_max: bool
@export var value: float: set = set_value
@export var step: float = 0.1 ##The value that will be added when the arrows are been pressed.

@export var shift_step_mult: float = 2.0##When pressing [param KEY_SHIFT], the [param value] will be multiplicated for this value.
@export var int_value: bool: 
	set(_v): int_value = _v; update_value_text()
var _call_emit: bool = true
#endregion

#region Nodes
@onready var line_edit := $Value
@onready var button_up = $ButtonUp
@onready var button_down = $ButtonDown
@onready var _value_nodes: Array = [line_edit,button_up,button_down]

#endregion

signal value_changed(value: float) ##Called when the value changes.
signal value_added(value: float) ##Called when the value changes, returns the value added
func _ready(): 
	update_value_text()
	minimum_size_changed.connect(_update_nodes_position.call_deferred)

#region Value Methods
func addValue() -> void: 
	var _r_step = ceilf(step) if int_value else step
	value += _r_step*shift_step_mult if Input.is_action_pressed("shift") else _r_step

func subValue() -> void: 
	var _r_step = ceilf(step) if int_value else step
	value -= _r_step*shift_step_mult if Input.is_action_pressed("shift") else _r_step

func set_value_no_signal(_value: float):
	_call_emit = false
	value = _value
	_call_emit = true
	
func set_value(_value: float):
	if limit_min: _value = max(_value,min)
	if limit_max: _value = min(_value,max)
	
	var emit: bool = _call_emit and value != _value
	var difference: float = _value - value
	value = snappedf(_value,0.0001)
	update_value_text()
	if !emit: return
	value_changed.emit(_value)
	value_added.emit(difference)

func _on_value_text_submitted(new_text: String) -> void:
	value = float(new_text)
	line_edit.release_focus()
#endregion


func _draw() -> void: _update_nodes_position()

func _update_nodes_position():
	var width: float = get_combined_minimum_size().x + 4
	var min_center = size.y*0.5
	for i in _value_nodes:
		i.position.x = width
		width += i.size.x + 2
		i.position.y = min_center - i.size.y/2.0
	line_edit.position.x -= 4

func update_value_text()  -> void:
	if !line_edit: return
	var value_int = int(value)
	if int_value or value_int == value: _value_str = String.num_int64(value_int)
	else: _value_str = String.num(value)
	_set_value_text()

func _set_value_text() -> void: if line_edit: line_edit.text = prefix+_value_str+suffix
