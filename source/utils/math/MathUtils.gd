class_name MathUtils

static func mix(current: Variant,target: Variant,value: float):
	target = type_convert(target,typeof(current))
	return current + (target - current)*value


static func is_pos_in_area(pos: Vector2, area_pos: Vector2, area_size: Vector2) -> bool:
	return pos.x >= area_pos.x and pos.x <= area_pos.x + area_size.x and \
			pos.y >= area_pos.y and pos.y <= area_pos.y + area_size.y

static func is_area_in_another_area(area1: Vector2, area1_size: Vector2, area2: Vector2, area2_size: Vector2) -> bool:
	return Rect2(area1,area1_size).intersects(Rect2(area2,area2_size))
	
static func is_pos_in_areas(pos: Vector2, areas_pos: Array, areas_sizes: Array) -> bool:
	for i in areas_pos.size(): if is_pos_in_area(pos,areas_pos[i],areas_sizes[i]): return true
	return false 

const numbers: PackedInt32Array = [TYPE_INT,TYPE_FLOAT]
static func is_number(variable: Variant) -> bool:
	return typeof(variable) in numbers


const type_strings: Dictionary[StringName,int] = {
	&'string': TYPE_STRING,
	&'stringname': TYPE_STRING_NAME,
	&'float': TYPE_FLOAT,
	&'bool': TYPE_BOOL,
	&'int': TYPE_INT,
	&'array': TYPE_ARRAY,
	&'packedstringarray': TYPE_PACKED_STRING_ARRAY,
	&'dictionary': TYPE_DICTIONARY,
	&'vector2': TYPE_VECTOR2,
	&'vector2i': TYPE_VECTOR2I,
	&'vector3': TYPE_VECTOR3,
	&'vector3i': TYPE_VECTOR3I,
	&'vector4': TYPE_VECTOR4,
	&'vector4i': TYPE_VECTOR4I,
	&'rect2': TYPE_RECT2,
	&'rect2i': TYPE_RECT2I,
	&'color': TYPE_COLOR,
	&'null': TYPE_NIL
}
const indexable_types: Dictionary = {
	TYPE_DICTIONARY: true,
	TYPE_OBJECT: true,
	TYPE_ARRAY: true,
	TYPE_PACKED_BYTE_ARRAY: true,
	TYPE_PACKED_FLOAT32_ARRAY: true,
	TYPE_PACKED_FLOAT64_ARRAY: true,
	TYPE_PACKED_INT32_ARRAY: true,
	TYPE_PACKED_STRING_ARRAY: true,
	TYPE_PACKED_VECTOR2_ARRAY: true,
	TYPE_PACKED_VECTOR3_ARRAY: true,
	TYPE_PACKED_VECTOR4_ARRAY: true,
	TYPE_PACKED_COLOR_ARRAY: true,
}
const math_types: Dictionary = {
	TYPE_FLOAT: true,
	TYPE_INT: true,
	TYPE_VECTOR2: true,
	TYPE_VECTOR3: true,
	TYPE_VECTOR4: true,
	TYPE_VECTOR2I: true,
	TYPE_VECTOR3I: true,
	TYPE_VECTOR4I: true,
	TYPE_RECT2: true,
	TYPE_RECT2I: true,
	TYPE_COLOR: true,
}

static func get_type_by_name(type: StringName) -> Variant.Type: return type_strings.get(type.to_lower() as StringName,TYPE_NIL)

static func convert_get_type_by_name(value: Variant, type: StringName) -> Variant: return type_convert(value,get_type_by_name(type))

static func get_new_value(type: int) -> Variant:
	match type:
		TYPE_FLOAT: return 0.0
		TYPE_INT: return 0
		TYPE_ARRAY: return Array()
		TYPE_BOOL: return false
		TYPE_PACKED_BYTE_ARRAY: return PackedByteArray()
		TYPE_PACKED_COLOR_ARRAY: return PackedColorArray()
		TYPE_PACKED_FLOAT32_ARRAY: return PackedFloat32Array()
		TYPE_PACKED_FLOAT64_ARRAY: return PackedFloat64Array()
		TYPE_PACKED_INT32_ARRAY: return PackedInt32Array()
		TYPE_PACKED_INT64_ARRAY: return PackedInt64Array()
		TYPE_PACKED_STRING_ARRAY: return PackedStringArray()
		TYPE_PACKED_VECTOR2_ARRAY: return PackedVector2Array()
		TYPE_PACKED_VECTOR3_ARRAY: return PackedVector3Array()
		TYPE_PACKED_VECTOR4_ARRAY: return PackedVector4Array()
		TYPE_DICTIONARY: return {}
		TYPE_VECTOR2: return Vector2.ZERO
		TYPE_VECTOR2I: return Vector2i.ZERO
		TYPE_VECTOR3: return Vector3.ZERO
		TYPE_VECTOR3I: return Vector3i.ZERO
		TYPE_VECTOR4: return Vector4.ZERO
		TYPE_VECTOR4I: return Vector4i.ZERO
		TYPE_STRING: return ''
		TYPE_STRING_NAME: return &''
		TYPE_NODE_PATH: return ^''
		TYPE_COLOR: return Color.WHITE
		TYPE_BOOL: return false
		TYPE_BASIS: return Basis()
		_: return null

static func value_is_indexable(value: Variant) -> bool:
	for i in indexable_types: if is_instance_of(value,i): return true
	return false


const properties_from_types: Dictionary[int,Variant] = {
	TYPE_RECT2: [&"position",&"size"],
	TYPE_RECT2I: [&"position",&"size"],
	TYPE_VECTOR2: [&"x",&"y"],
	TYPE_VECTOR2I: [&"x",&"y"],
	TYPE_VECTOR3: [&"x",&"y",&'z'],
	TYPE_VECTOR3I: [&"x",&"y",&'z'],
	TYPE_VECTOR4: [&"x",&"y",&'z',&"w"],
	TYPE_VECTOR4I: [&"x",&"y",&'z',&"w"],
	TYPE_COLOR: [&'r',&'g',&'b',&'a',&'x',&'y',&'z',&'w']
}
static func property_exists(obj: Variant, property: Variant) -> bool:
	var type = typeof(obj)
	var values = properties_from_types.get(type)
	
	if values: return property in values
	
	if ArrayUtils.is_array_type(type): return ArrayUtils.array_has_index(obj,int(property))
	match type:
		TYPE_OBJECT,TYPE_DICTIONARY: return property in obj
	return false
