class_name EventNote extends Resource

var t: float = 0.0 ##The time position of the event
var e: StringName ##Event name
var v: Dictionary ##The variables of the event
var player: bool = true ##If [code]true[/code], the event will be trigged when are playing as player(boyfriend). 
var opponent: bool = true ##If [code]true[/code], the event will be trigged when are playing as opponent(dad). 

static func get_chart_data_to_json(data: Dictionary) -> Dictionary:
	var dict = {
		&"t": data.t,
		&"e": data.e,
	}
	if !data.get("trigger_when_opponent",true): dict.trigger_when_opponent = false
	if !data.get("trigger_when_player",true): dict.trigger_when_player = false
	
	if !data.get("v"): return dict
	dict.v = {}
	for i in data.v:
		var value = data.v[i]
		match typeof(value):
			TYPE_VECTOR2,TYPE_VECTOR2I: value = [value.x,value.y]
			TYPE_VECTOR3,TYPE_VECTOR3I: value = [value.x,value.y,value.z]
			TYPE_VECTOR4,TYPE_VECTOR4I: value = [value.x,value.y,value.z,value.w]
			TYPE_COLOR: value = value.to_html()
		dict.v[i] = value
	return dict

static func loadEventsFromChart(events_data: Array, game_mode: PlayStateBase.GameMode = PlayStateBase.GameMode.MODE_2D) -> Array[EventNote]:
	var events: Array[EventNote]
	for i in events_data:
		var e
		if i is Dictionary: 
			e = create_from_event_data(i); if e: _add_event_to_array(events,e)
		elif i is Array: 
			e = create_events_from_array(i, game_mode); 
			if e: for event in e: _add_event_to_array(events, event)
	return events

static func _add_event_to_array(array: Array, e: EventNote):
	var i: int = array.size()
	while i and e.t < array[i-1].t: i -= 1
	array.insert(i,e)

static func fix_variables(
	event: StringName, variables: Dictionary
	) -> void:
	var event_data = EventData.get_event_data(event)
	var vars = event_data.get("variables")
	if !vars: variables.clear(); return
	for i in vars:
		var value = variables.get(i)
		if value == null: variables[i] = vars[i].default 
		else: variables[i] = type_convert(value,vars[i].type)

static func create_from_event_data(data: Dictionary) -> EventNote:
	var event_name = data.get("e","")
	var event = EventNote.new()
	event.t = data.get("t",0.0)
	event.e = event_name
	
	var v: Dictionary = data.get("v",{})
	v.merge(EventData.get_event_default_variables(event_name),false)
	if v: event.v = v 
	
	return event

static func create_events_from_array(data: Array, mode: PlayStateBase.GameMode = PlayStateBase.GameMode.MODE_2D) -> Array[EventNote]:
	if !data: return []
	var events: Array[EventNote]
	var time = data[0]
	for i in data[1]:
		var event_name = i[0]
		var event: EventNote = EventNote.new()
		event.t = time
		event.e =  event_name
		event.v = get_values_from_array(event_name,i.slice(1), mode)
		events.append(event)
	return events

static func get_event_value_converted(value: Variant, type: Variant.Type):
	return MathUtils.get_new_value(type) if value == null else type_convert(value,type)

static func get_values_from_array(event: StringName, array: Array, mode: PlayStateBase.GameMode = PlayStateBase.GameMode.MODE_2D) -> Dictionary[StringName, Variant]:
	var values: Dictionary[StringName, Variant]
	var event_data = EventData.get_event_data(event)
	if !event_data: 
		match mode:
			PlayStateBase.GameMode.MODE_2D: event_data = EventData.get_event_data("2d/"+event)
			PlayStateBase.GameMode.MODE_3D: event_data = EventData.get_event_data("3d/"+event)
	var vars: Dictionary
	
	if event_data:
		vars = event_data.get("variables")
		if !vars: vars = EventData.get_base_variables_typed()
	else: vars = EventData.get_base_variables_typed()
	
	var i: int = 0
	var vars_keys = vars.keys()
	var vars_length = vars.size()
	var length = array.size()
	while i < vars_length:
		var key = vars_keys[i]
		if i < length:
			values[key] = get_event_value_converted(array[i],vars[key].type)
		else:
			var default = vars[key].get("default")
			if default == null: default = MathUtils.get_new_value(vars[key].type)
			values[key] = default
		i += 1
	return values

static func get_base_data() -> Dictionary[StringName, Variant]: return {&"t": 0.0, &"e": &"", &"v": {}}
