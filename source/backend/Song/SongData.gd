@tool
class_name SongData extends Resource ##A Chart Song Class.
const DEFAULT_ARROW_STYLE: StringName = &"funkin"
const DEFAULT_ARROW_PIXEL_STYLE: StringName = &"pixel"
const DEFAULT_SPLASH_STYLE: StringName = &"NoteSplashes"
const DEFAULT_SPLASH_HOLD_STYLE: StringName = &"HoldNoteSplashes"
enum EditorMode{
	NONE,
	FREEPLAY,
	PLAYSTATE,
	EVENTS
}

var _editor_mode: EditorMode = EditorMode.NONE:
	set(val): _editor_mode = val; notify_property_list_changed()

@export var mod: String ##The mod that contains all the files of the song.
@export_group("Song Data")
@export var data: Dictionary ##Song Data

var sections: Array:
	get(): return data.get_or_add("notes",[])

@export var songName: String ##The Song's Name
@export var difficulty: String ##Song Difficulty

@export_file("*.json") var json: String
var json_folder: String
@export_file("*.tscn") var packedScene: String = "uid://bo0fdh4ajdrir"

var keyCount: int = 4

@export_group("Audio Data")
@export_dir var audioFolder: String
@export var audioSuffix: String
@export var opponentVocals: String
@export var playerVocals: String


@export_group("Freeplay Properties")
@export var difficulties: PackedStringArray = ["easy","normal","hard"]
@export var difficulty_colors: Dictionary[StringName, Color]
@export var bg_color: Color = Color.WHITE


##The song icon texture.[br] 
##[b]OBS:[/b] If the icon is not in the project folder, use [member icon_name].
@export var icon: Texture 

##The song icon name, 
##used if the icon is not in the project folder, but in the external game folder ("assets/images", use this variable.
@export var icon_name: String
@export var icon_has_states: bool = true ##If [code]true[/code], the [param icon] will be split.

static func load_from_json(path_absolute: String):
	var song = SongData.new()
	song.data = Paths.load_json_absolute(path_absolute)
	song.json = path_absolute
	song.json_folder = path_absolute.get_base_dir()
	song.songName = path_absolute.get_file().get_basename()

func load_data(): 
	if !data: 
		var path = PathsStore.song_data(json if json else songName, difficulty)
		if path: 
			data = FunkinChartParser.load_data(path); 
			json = path
			json_folder = path.get_base_dir()
	sections = data.get("notes",[]); keyCount = data.get("keyCount",4)

func getArrowStyle(is_pixel: bool = false) -> StringName:
	var style = data.get("arrowStyle")
	if style: return style 
	return DEFAULT_ARROW_PIXEL_STYLE if is_pixel else DEFAULT_ARROW_STYLE

func getSplashStyle(default: StringName = DEFAULT_SPLASH_STYLE) -> StringName:
	var hold = data.get('splashStyle'); return hold if hold else default

func getSplashHoldStyle(default: StringName = DEFAULT_SPLASH_HOLD_STYLE) -> StringName: 
	var hold = data.get('splashHoldStyle'); return hold if hold else default

func _validate_property(property: Dictionary) -> void:
	match StringName(property.name):
		&"difficulties",&"difficulty_colors",&"bg_color",&"icon",&"icon_name",&"icon_has_states":
			match _editor_mode:
				EditorMode.NONE, EditorMode.FREEPLAY: property.usage = PROPERTY_USAGE_DEFAULT
				_: property.usage = PROPERTY_USAGE_NONE
		&"difficulty":
			match _editor_mode:
				EditorMode.FREEPLAY, EditorMode.EVENTS: property.usage = PROPERTY_USAGE_NONE
				_: property.usage = PROPERTY_USAGE_DEFAULT
		&"data", &"songName", &"json", &"packedScene":
			match _editor_mode:
				EditorMode.EVENTS: property.usage = PROPERTY_USAGE_NONE
				_: property.usage = PROPERTY_USAGE_DEFAULT
#region Setters
