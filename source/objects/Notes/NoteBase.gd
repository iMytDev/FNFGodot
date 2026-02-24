@abstract
class_name NoteBase extends FunkinAnimatedSprite2D

const Song = preload("uid://cerxbopol4l1g")

const directions: PackedStringArray = ['left','down','up','right']
const note_colors: PackedStringArray = ['Purple','Blue','Green','Red']

var styleData: NoteStyleData = NoteStyleData.new()
var styleName: StringName
var stylePrefix: String

var noteData: int = 0: set = set_note_data ##The direction of this Note.
var noteDirection: String = ''
var sustainLength: float: set = _set_sustain_length

#region Note Styles
var isPixelNote: bool = false: set = set_pixel_note ##Is Pixel Note
var texture: String: set = set_note_texture ##Note Texture

var noteScale: float = NoteStyleData.DEFAULT_NOTES_SCALE
var noteAngle: float = 0.0
#endregion

#region Rhytm Properties
var stepCrochet: float ##The stepCrochet of the note, is set in [NoteParser].
var mustPress: bool

func _init(): super(); image.texture_changed.connect(animation.clearLibrary)

func loadFromStyle(noteStyle: StringName):
	styleName = noteStyle
	styleData.load_from_style_json(noteStyle, _get_note_style_key())
	
	set_style_prefix()
	_update_note_from_style()

#region Setters
func set_style_prefix(prefix: StringName = _get_style_prefix_name()):
	stylePrefix = prefix; _update_note_from_style()

func _set_sustain_length(l: float): #Replaced in NoteSustain/NoteChart
	if l < 0.0: l = 0.0
	sustainLength = l;

##Reload the Note animation and his texture.
@abstract func reloadNote() -> void

#region Setters
func set_note_data(_data: int) -> void: noteData = _data; noteDirection = directions[_data]; set_style_prefix()

func _get_style_prefix_name() -> StringName: #Replaced in NoteSustain
	if styleData.data.has(noteDirection): return noteDirection
	return &"default" if styleData.data.has(&"default") else &""

func set_pixel_note(isPixel: bool) -> void:
	texture_filter = TEXTURE_FILTER_NEAREST if isPixel else TEXTURE_FILTER_LINEAR
	isPixelNote = isPixel

func set_note_texture(_new_texture: String) -> void:
	if texture == _new_texture: return
	texture = _new_texture
	image.texture = Paths.texture(_new_texture)
	reloadNote()

func _update_note_from_style():
	noteAngle = deg_to_rad(styleData.get_angle(noteDirection))
	offset = styleData.get_offsets(noteDirection)
	isPixelNote = styleData.is_pixel(noteDirection)
	noteScale = styleData.get_scale(noteDirection)
	rotation = noteAngle
	image.scale = Vector2(noteScale,noteScale)
	texture = styleData.get_asset_path(noteDirection)

#Replaced in NoteSustain
func _get_note_style_key() -> StringName: return &"notes"

#region Static Funcs
static func note_is_must_press(note_direction: int, must_hit_section: bool, keycount: int = Conductor.songData.keyCount) -> bool:
	return note_direction < keycount if must_hit_section else note_direction >= keycount
