@tool
class_name CameraShake extends Resource

var _real_intensity: float
@export_range(0.0,1.0,0.01) var intensity: float:
	set(val): 
		intensity = val; 
		_update_intensity()

@export var time: float:
	set(val): 
		val = maxf(0.0,val)
		time = val; 
		if Engine.is_editor_hint(): _reset_time(); 

@export var looped: bool

@export var fade_in: bool:
	set(val):
		fade_in = val; 
		_update_intensity(); 
		notify_property_list_changed()

##The time percent the fade needs to be completed.
@export_range(0.0,1.0,0.05) 
var fade_in_time_progress: float = 0.25:
	set(val): 
		val = minf(fade_out_time_progress, val)
		fade_in_time_progress = val; 
		if fade_out_time_progress < val: fade_out = val;
		else: _update_intensity()

@export var fade_out: bool:
	set(val): 
		fade_out = val; 
		notify_property_list_changed()

@export_range(0.0,0.9,0.05) 
var fade_out_time_progress: float = 0.8:
	set(val):
		val = maxf(fade_in_time_progress, val)
		fade_out_time_progress = val
		if fade_in_time_progress > val: fade_in_time_progress = val;
		else: _update_intensity()

var cur_time: float = 0.0: 
	set(val): cur_time = val; _update_intensity()

@export_tool_button("Reset Shake") var r = _reset_time

func _reset_time(): cur_time = 0.0

func _init(_intensity: float = 0.0, _time: float = 0.0) -> void:
	intensity = _intensity 
	time = _time

func get_real_intensity() -> float: return _real_intensity

func _update_intensity() -> void:
	_real_intensity = intensity
	var progress = cur_time / time
	
	if !time: return
	
	if fade_out:
		var smooth = smoothstep(0.0,1.0 - fade_out_time_progress, 1.0 - progress)
		_real_intensity *= smooth
	if fade_in:
		_real_intensity *= smoothstep(0.0,fade_in_time_progress, progress)
	
func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"fade_in_time_progress": 
			property.usage = PROPERTY_USAGE_DEFAULT if fade_in else PROPERTY_USAGE_NONE
		&"fade_out_time_progress": 
			property.usage = PROPERTY_USAGE_DEFAULT if fade_out else PROPERTY_USAGE_NONE
			
		&"cur_time":
			property.usage = PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_NO_INSTANCE_STATE
