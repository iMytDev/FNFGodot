class_name EventData extends Resource
static var datas_loaded: Dictionary[StringName, EventData]

@export var variables: Dictionary[StringName, Dictionary]
@export var description: String
@export var icon: String:
	set(val): icon = val; icon_texture = Paths.texture(val)
var icon_texture: Texture2D
func get_data_to_json() -> Dictionary[StringName, Variant]:
	return {
		&"variables": variables,
		&"description": description,
		&"icon": icon
	}

func get_chart_data_to_json() -> Dictionary[StringName, Variant]:
	return {}

#region Data
static func load_from_json(dict: Dictionary) -> EventData:
	var data = EventData.new()
	data.description = dict.get("description","")
	
	var icon = dict.get("icon","")
	if icon: data.icon = Paths.texture(icon)
	var vars = dict.get("variables"); 
	if !vars: return data
	
	for i in vars:
		var d = vars[i]
		var event_value = EventValueType.new()
		var value: Variant
		var default = d.get("default")
		event_value.type_string = d.get("type","String")
		
		if default == null: value = MathUtils.get_new_value(event_value.type)
		else:
			match event_value.type:
				TYPE_VECTOR2: value = Vector2(default[0],default[1])
				TYPE_VECTOR3I: value = Vector2i(default[0],default[1])
				TYPE_VECTOR3: value = Vector3(default[0],default[1],default[2])
				TYPE_VECTOR3I: value = Vector3i(default[0],default[1],default[2])
				TYPE_VECTOR4: value = Vector4(default[0],default[1],default[2],default[3])
				TYPE_VECTOR4I: value = Vector4i(default[0],default[1],default[2],default[3])
				_: value = default
		
		event_value.default = value
		data.variables[i] = event_value
	return data
static func clear() -> void: datas_loaded.clear()

static func get_event_data(event_name: StringName) -> EventData:
	var data = datas_loaded.get(event_name); if data: return data
	var json = get_event_json(event_name); if !json: return
	
	data = EventData.new()
	#data.name = event_name
	
	var vars = json.get("variables")
	if vars:
		for i in vars:
			var d = vars[i]
			var v_data = {
				&"type": TYPE_STRING,
				&"default": ""
			}
			var t =  d.get("type")
			if t: v_data.type_string = t
			
			var def = d.get("default")
			if def: v_data.default = def
			data.variables[i] = v_data
	datas_loaded[event_name] = data
	return data
static func get_event_json(event_name: StringName) -> Dictionary:
	return Paths.loadJson("custom_events/"+event_name+".json")

static func get_event_default_variables(event_name: StringName, mode: PlayStateBase.GameMode = PlayStateBase.GameMode.MODE_2D) -> Dictionary[StringName, Variant]:
	var v: Dictionary[StringName, Variant]
	var data: EventData = get_event_data(event_name)
	if !data:
		match mode:
			PlayStateBase.GameMode.MODE_2D: data = get_event_data("2d/"+event_name)
			PlayStateBase.GameMode.MODE_3D: data = get_event_data("3d/"+event_name)
		if !data: return get_base_variables_typed()
		return v
	for i in data.variables: v[i] = data.variables[i].default
	return v

static func _get_event_variables(event_data: Dictionary):
	for i in event_data:
		var d = event_data[i]
		var t = d.get("type")
		d.type = MathUtils.get_type_by_name(t) if t else TYPE_STRING
#endregion


static func get_base_variables() -> Dictionary[StringName, Variant]: return {&"value1": "",&"value2": ""}

static func get_base_variables_typed() -> Dictionary[StringName,Dictionary]:
	return {
		&"value1": {&"type": TYPE_STRING, &"default": ""},
		&"value2": {&"type": TYPE_STRING, &"default": ""},
	}
