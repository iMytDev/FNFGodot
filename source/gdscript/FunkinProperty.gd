class_name FunkinProperty extends FunkinInternal
const alternative_variables: Dictionary = {
	'angle': 'rotation_degrees',
	'color': 'modulate',
	'origin': 'pivot_offset'
}
const property_replaces: Dictionary = {
	'[': '.',
	']': ''
}

#region Setter Methods
static func set_property(property: String, value: Variant):
	var obj_find = _get_property_split(property,true)
	var target = obj_find[0]
	var split = obj_find[1]
	if target: set_object_property_split(split,value,target); return
	
	if split.size() > 1: debug_error('Error on setting "'+property.right(-split[0].length()-1)+'" property: '+split[0]+" not founded")
	else: debug_error('Error on setting property: "'+property+'" not founded')

static func set_object_property_split(split: PackedStringArray, value: Variant, object: Variant):
	var size: int = split.size()
	if size == 1: object.set(split[0],value); return
	
	var split_to_variable: PackedStringArray
	var object_to_set: Variant = object
	var cur_property: Variant = object
	var i: int = 0
	
	while i < size:
		var p = split[i]; i += 1
		if !MathUtils.property_exists(cur_property,p): 
			debug_error('Error on setting property: '+str(p)+" not founded in "+str(cur_property))
			return
		
		if MathUtils.value_is_indexable(cur_property):
			object_to_set = cur_property; 
			split_to_variable.clear();
		
		cur_property = cur_property[p]
		split_to_variable.append(p)
	
	
	set_property_from_array(object_to_set,split_to_variable,value)

static func set_property_from_array(obj: Variant, property: PackedStringArray, value: Variant):
	match property.size():
		1: obj.set(property[0],value)
		2: obj[property[0]][property[1]] = value
		3: obj[property[0]][property[1]][property[2]] = value
		4: obj[property[0]][property[1]][property[2]][property[3]] = value
		5: obj[property[0]][property[1]][property[2]][property[3]][property[4]] = value
#endregion

#region Getter Methods
static func get_property(property: String) -> Variant: ##Get a Property from the game.
	var obj_split = _get_property_split(property);
	var split = obj_split[1];
	return get_object_property_split(split,obj_split[0]) if split else obj_split[0]

static func get_object_property_split(split: PackedStringArray, object: Variant) -> Variant:
	if !object: return null
	var index: int = 0
	var size = split.size()
	while index < size:
		object = _get_variable(object,split[index]); 
		if object == null: return null
		index += 1
	return object
#endregion


const source_dirs: PackedStringArray = [
	'res://source/',
	'res://source/backend',
	'res://source/states',
	'res://source/substates'
]
static func _find_class(object: String) -> Object:
	if Engine.has_singleton(object): return Engine.get_singleton(object)
	
	var tree = Global.get_tree().root
	if tree.has_node(object): return tree.get_node(object)
	object = object.replace('.','/')
	if not object.ends_with('.gd'): object += '.gd'
	
	for i in source_dirs: var path = i+object; if FileAccess.file_exists(path): return load(path)
	return null

static func _find_group_member(group: Variant, index: Variant) -> Variant:
	if group is String: group = _find_object(group); if !group: return
	if group is SpriteGroup: return group.members.get(index)
	if group is Array: return group.get(index)
	if group is Object or group is Dictionary: return group.get(index)
	return null

static func _find_object(property: Variant) -> Variant:
	if property is Object: return property
	var split = _get_as_property(property).split('.')
	var key = split[0]
	var value = _find_property(key)
	
	var index: int = 1
	while index < split.size():
		var variable = _get_variable(value,split[index])
		if variable == null: return null
		elif !is_indexable(variable): break
		value = variable
		index += 1
	return value

static func _find_property(property: StringName) -> Variant:
	var p
	if FunkinInternal.game: p = FunkinInternal.game.get(property); if p != null: return p
	for i in FunkinInternal.dictionariesToCheck: p = i.get(property); if p != null: return p
	return null

static func _find_property_owner(property: StringName):
	if FunkinInternal.game and property in FunkinInternal.game: return FunkinInternal.game
	for i in FunkinInternal.dictionariesToCheck: if i.has(property): return i
	return null

static func _get_variable(obj: Variant, variable: String) -> Variant:
	var type = typeof(obj)
	if ArrayUtils.is_array_type(type): return obj.get(int(variable))
	if VectorUtils.is_vector_type(type): return obj[variable]
	
	match type:
		TYPE_DICTIONARY: return obj.get(variable)
		TYPE_OBJECT: 
			var value = obj.get(variable)
			if value == null and variable.find(':'): value = obj.get_indexed(variable)
			if value == null and variable in alternative_variables: return _get_variable(obj,alternative_variables[variable])
			return value
		TYPE_COLOR: return obj[variable]
		_: return null

static func _get_property_split(property: Variant, to_set: bool = false) -> Array:
	var split = _get_as_property(property).split('.')
	var key = split[0]
	var object
	var size: int = split.size()
	
	var index: int = 0
	if to_set:
		object = _find_property_owner(key)
		size -= 1
	else:
		object = _find_property(key)
		index = 1
	if to_set: size -= 1
	while index < size:
		var variable = _get_variable(object,split[index])
		if variable == null: return [null, split]
		elif !is_indexable(variable): break
		object = variable
		index += 1
	return [object,split.slice(index)]


static func _get_as_property(property: String) -> String:
	return StringUtils.replace_chars_from_dict(property,property_replaces)

static func is_indexable(variable: Variant) -> bool:
	if !variable: return false
	var type = typeof(variable)
	
	if ArrayUtils.is_array_type(type):return true
	match type:
		TYPE_OBJECT,TYPE_DICTIONARY: return true
		_: return false
