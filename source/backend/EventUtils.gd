static var events_data: Dictionary
static var easing_types: PackedStringArray

##A script to help with Event Notes.
static func _get_events_chart_data(events: Array) -> Array[Dictionary]:
	var new_events: Array[Dictionary]
	var event_base = _get_event_base()
	for data in events:
		if data is Array: new_events.append_array(_convert_event_to_new(data))
		else:
			var event_vars = get_event_variables(data.e)
			data.merge(event_base,false);
			if data.v is Dictionary: 
				for i in event_vars: if !data.v.has(i): data.v[i] = event_vars[i].default_value
			else:
				var val = data.v
				data.v = {}
				for i in event_vars: data.v[i] = event_vars[i].default_value
				data.v[event_vars.keys()[0]] = val
			new_events.append(data)
	return new_events

static func _convert_event_to_new(data: Array) -> Array[Dictionary]:
	var new_events: Array[Dictionary]
	for i in data[1]:
		var event = _get_event_base()
		var event_name: StringName = i[0]
		var variables = get_event_variables(event_name)
		var vars_keys = variables.keys()
		var keys_length = vars_keys.size()
		var event_length = minf(i.size()-1,keys_length)
		event.t = data[0]
		event.e = event_name
		
		var index: int = 0
		while index < event_length:
			var key = vars_keys[index]
			var val = i[index+1]
			event.v[key] = _convert_event_value_type(
				val,
				variables[key].get(&'type',TYPE_NIL),
				val
			)
			index += 1
		
		while index < keys_length:
			var key = vars_keys[index]
			event.v[key] = variables[key].default_value
			index += 1
		new_events.append(event)
	return new_events

static func _convert_event_value_type(value: Variant, type: Variant.Type, default_value: Variant = null):
	if value == null: return MathUtils.get_new_value(type)
	var value_type = typeof(value)
	match type:
		TYPE_NIL: return value
		TYPE_FLOAT,TYPE_INT: if value_type == TYPE_STRING and !value and default_value: return default_value
	return type_convert(value,type)

static func loadEvents(chart: Array) -> Array[Dictionary]:
	var events = _get_events_chart_data(chart)
	events.sort_custom(func(a,b):return a.t < b.t)
	return events

#region Chart Methods



const default_value_data: Dictionary = {
	&"type": TYPE_STRING,
	&"default_value": &""
}

const default_variables = {
	&'value1': {
		&'type': TYPE_STRING,
		&'default_value': &''
	},
	&'value2': {
		&'type': TYPE_STRING,
		&'default_value': &''
	}
}


static func _get_event_base() -> Dictionary[StringName,Variant]:
	return {
		&'t': 0.0, #Time
		&'v': {}, #Variables
		&'e': &'', #Event
		&'trigger_when_opponent': true,
		&'trigger_when_player': true
	}

static func _get_transitions():
	var trans: PackedStringArray
	for i in TweenService.transitions:
		i = StringUtils.first_letter_upper(i)
		trans.append("#"+i)
		if i == &'': trans.append("Linear"); continue
		for e in TweenService.easings: trans.append(i+e)
		
	return trans

##Return the variables of the a custom_event using "@vars" in his text.[br]
##The function returns a [Dictionary] that contains an [Array] with its type and its default value.[br][br]
##[b]Example:[/b] [code]{"value1": [TYPE_STRING,''], "value2": [TYPE_FLOAT,0.0]}[/code]

static func get_event_data(event_name: StringName) -> Dictionary[StringName, Variant]: 
	var data = events_data.get(event_name)
	if data: return data
	data = get_event_data_no_cache(event_name)
	events_data[event_name] = data
	return data
	
static func get_event_data_no_cache(event_name: String) -> Dictionary[StringName, Variant]:
	var json = DictUtils.getDictTyped(
		Paths.loadJsonNoCache('custom_events/'+event_name+'.json'),
		TYPE_STRING_NAME
	)
	if !json: return json
	var variables = json.get('variables')
	if !variables: 
		json.variables = default_value_data.duplicate()
		return json
	
	for i in variables: _fix_variable_data(variables[i])
	return json

static func get_event_variables(event_name: StringName) -> Dictionary:
	var data = get_event_data(event_name)
	if !data: return default_variables.duplicate()
	return data.get('variables',{})

static func get_event_variables_no_cache(event_name: StringName) -> Dictionary[StringName, Variant]:
	var event_data: Dictionary[StringName,Variant] = get_event_data(event_name)
	if !event_data or !event_data.has(&'variables'): return default_variables
	return event_data.variables

static func get_event_default_values(event_name: StringName) -> Dictionary[StringName,Variant]:
	var default: Dictionary[StringName,Variant]
	var variables = get_event_variables(event_name)
	for i in variables: default[i] = variables[i].default_value
	return default

static func _fix_variable_data(data: Dictionary) -> Dictionary:
	var type: StringName = data.get(&'type',&'String')
	
	var value_type: int
	var options: Array = data.get(&'options',[])
	match type:
		&'EasingType':
			options.append_array(easing_types)
			value_type = TYPE_STRING
		_: value_type = MathUtils.get_type_by_name(type)
	
	var default_value: Variant = data.get('default_value','')
	var look_at = data.get('look_at')
	if look_at:
		var directory = look_at.get('directory')
		if directory:
			var extension = look_at.get('extension','')
			var files_founded: PackedStringArray
			var last_mod: String
			for i in Paths.getFilesAt(directory,true,extension):
				var file = i.get_file()
				if file in files_founded: continue
				var mod = Paths.getModFolder(i)
				if last_mod != mod:
					last_mod = mod
					options.append('#'+mod)
				files_founded.append(file)
				options.append(file)
	if options: data.options = options; default_value = options[0]
	else: default_value = type_convert(default_value,value_type)
	
	data.type = value_type
	
	match value_type:
		TYPE_VECTOR2: data.default_value = Vector2(default_value[0],default_value[1])
		TYPE_VECTOR2I: data.default_value = Vector2i(default_value[0],default_value[1])
		TYPE_VECTOR3: data.default_value = Vector3(default_value[0],default_value[1],default_value[2])
		TYPE_VECTOR3I: data.default_value = Vector3i(default_value[0],default_value[1],default_value[2])
		_: data.default_value = default_value
	
	return data
#endregion
