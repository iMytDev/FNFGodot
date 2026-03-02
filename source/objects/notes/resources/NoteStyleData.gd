@tool
class_name NoteStyleData extends Resource
static var styles_loaded: Dictionary[StringName,Dictionary]
const DEFAULT_NOTES_SCALE: float = 0.7

enum StyleType{
	NOTES,
	SPLASH
}

var assetPath: StringName
var scale: float = DEFAULT_NOTES_SCALE
var data: Dictionary
var isPixel: bool
var prefix: String
var offsets: Vector2
var keyCount: int = 4
var angle: float

func is_full_image(anim: StringName = &""): return _get_property_from_anim(anim, &"use_full_image", isPixel)
func is_pixel(anim: StringName = &"") -> bool: return _get_property_from_anim(anim,&"isPixel", isPixel)
func get_asset_path(anim: StringName = &"") -> StringName: return _get_property_from_anim(anim,&"assetPath", assetPath)
func get_scale(anim: StringName = &"") -> float: return _get_property_from_anim(anim,&"scale", scale)
func get_offsets(anim: StringName = &"") -> Vector2: return _get_property_from_anim(anim, &"offsets", offsets)
func get_angle(anim: StringName = &"") -> float: return _get_property_from_anim(anim, &"angle", angle)

func load_from_style_json(style: StringName, key: StringName = &"strums", type: StyleType = StyleType.NOTES) -> void:
	var json = getStyleData(style,key,type); if !json: return
	assetPath = json.get(&"assetPath",&'')
	scale = json.get(&"scale",DEFAULT_NOTES_SCALE)
	data = json.get(&"data",{})
	angle = json.get(&"angle",0.0); if angle: angle = deg_to_rad(angle)
	keyCount = json.get(&"keyCount",4)

func _get_property_from_anim(anim: StringName, key: StringName, default: Variant) -> Variant:
	var d = data.get(anim); if !d: d = data.get(&"default")
	return d.get(key,default) if d != null else default

static func create_from_style_json(style: StringName, key: StringName = &"strums", type: StyleType = StyleType.NOTES) -> NoteStyleData:
	var data = NoteStyleData.new()
	data.load_from_style_json(style,key,type)
	return data

static func getStyleData(style: StringName, splash_name: StringName = &'strums', type: StyleType = StyleType.NOTES) -> Dictionary: 
	var json: Dictionary = _load_style(style,type);
	return json.get(splash_name,{}) if json else {}

static func _load_style(style: StringName, type: StyleType = StyleType.NOTES) -> Dictionary[StringName,Dictionary]:
	var json = styles_loaded.get(style); #Check if the style is already created.
	if json: return json
	
	match type:
		StyleType.SPLASH: json = Paths.loadJson('data/splashstyles/'+style)
		_: json = Paths.loadJson('data/notestyles/'+style)
	
	if !json: return json
	
	#Convert the json keys to StringName.
	json = DictUtils.getDictTyped(json,TYPE_STRING_NAME,TYPE_DICTIONARY)
	
	match type:
		StyleType.SPLASH:
			if json.has(&'holdNoteCover'): _fix_data(json.holdNoteCover,StyleType.SPLASH)
			if json.has(&'noteSplash'): _fix_data(json.noteSplash ,StyleType.SPLASH)
		_:
			if json.has(&'strums'): _fix_data(json.strums)
			if json.has(&'notes'): _fix_data(json.notes)
			if json.has(&'holdNote'): _fix_data(json.holdNote)
	styles_loaded[style] = json
	return json

static func _fix_animation_data(data: Dictionary) -> void:
	var offs = data.get(&'offsets'); if offs != null: data.offsets = Vector2(offs[0],offs[1])

static func _check_animation_data(data: Variant) -> void:
	if data is Dictionary: _fix_animation_data(data)
	elif data is Array: for i in data: _fix_animation_data(i)

static func _fix_data(data: Dictionary, style: StyleType = StyleType.NOTES) -> void:
	_fix_animation_data(data)
	var anim_data = data.get(&'data'); if !anim_data: return
	match style:
		StyleType.SPLASH:
			for i in anim_data.values():
				if i.has(&'start'): _check_animation_data(i.start)
				if i.has(&'hold'): _check_animation_data(i.hold)
				if i.has(&'end'): _check_animation_data(i.end)
		_: 
			for i in anim_data.values(): _check_animation_data(i)
