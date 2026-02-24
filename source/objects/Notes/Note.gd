
@icon("res://icons/note.svg")
class_name Note extends "NoteSolid.gd" ##The Note Base Class
#region Constants
const NoteSplash = preload("uid://cct1klvoc2ebg")
#endregion

#region Copy Strum Properties
var copyX: bool = true  ##If [code]true[/code], the note will follow the x position from his [member strum].
var copyY: bool = true ##If [code]true[/code], the note will follow the y position from his [member strum].
var copyAlpha: bool = true ##If [code]true[/code], the note will follow the alpha from his [member strum].
var copyScale: bool ##If [code]true[/code], the note will follow the scale from his [member strum].
var copyAngle: bool = true ## Follow strum angle
#endregion

#region Sustain Properties
var isSustainNote: bool ##If the note is a Sustain. See also ["source/objects/NoteSustain.gd"]
var isEndSustain: bool
#endregion

#region Health Properties
var hitHealth: float = 0.023 ##the amount of life will gain by hitting the note
var missHealth: float = 0.0475##the amount of life will lose by missing the note
#endregion

#region Strum Properties
var strumConfirm: bool = true ##If [code]true[/code], the strum will play animation when hit the note
var strumTime: float ##Position of the note in the song
var strumNote: StrumNote: set = _set_strum ##Strum Parent that note will follow

var hit_actions: PackedInt32Array
#endregion

#region Note Style Properties
var noteSpeed: float = 1.0: set = _set_note_speed ##Note Speed
var _real_note_speed: float = 1.0

var noteType: String
var gfNote: bool ##Is GF Note

var ignoreNote: bool ##if is opponent note or a bot playing, they will ignore this note

var autoHit: bool ##If [code]true[/code], the note will be hit automatically, independent if is a player note.
var noAnimation: bool ##When hit the note and this variable is [code]true[/code], the character will dont play animation

var blockHit: bool ##Unable to hit the note

var lowPriority: bool ##if two notes are close to the strum and this variable is true, the game will prioritize the another one
#endregion

#region Mult Properties
var multSpeed: float = 1.0: set = set_mult_speed ##Note Speed multiplier
var multAlpha: float = 1.0 ##Note Alpha multiplier
var multScale: Vector2 = Vector2.ONE
#endregion

#region General Properties
##The group the note will be added when spawned,
##see [method "source/states/StrumState.gd".spawnNote] in his script for more information.[br][br]
##[b]Tip:[/b] Is recommend to set this value as a [SpriteGroup]!! 
var noteGroup: Node

var missOffset: float = -150.0 ##The time distance to miss the note

var missed: bool ##Detect if the note is missed

var offsetX: float ##Distance on x axis
var offsetY: float ##Distance on y axis

var distance: float: set = _set_distance  ##The distance between the note and the strum
var real_distance: float

var canBeHit: bool  ##If the note can be hit
var hitStrumAnim: StringName ##Strum animation when hit this note, this property is set in StrumState.
var hitAnim: StringName
var hitCharacter: Node ##The Character that will play the animation when this note are hit or missed. Used in PlayState

var wasHit: bool
var judgementTime: float = INF ##Used in ModchartEditor


#region Splash
var splashStyle: StringName = &'NoteSplashes' ##Splash Json
var splashName: StringName = &'noteSplash' ##Splash Type
var splashPrefix: StringName ##Splash Prefix
var splashDisabled: bool ##If [code]true[/code], when hits this note, the splash will not be created.
var splashParent: Node
#endregion

#endregion

#region Rating Variables
var ratingMod: int ## The Rating of the note in [int]. [param 0 = nothing, 1 = sick, 2 = good, 3 = bad, 4 = shit]
var rating: StringName ## The Rating ot the note in [String]. [param sick, good, bad, shit]
var ratingDisabled: bool ##Disable Rating. If [code]true[/code], the rating will always be "sick".
#endregion

func _init(data: int = 0) -> void: noteData = data; super()

func _can_hit() -> bool:
	if missed: return false
	if autoHit: return distance <= 0.0;
	var limit = ClientPrefs.data.note_hit_time
	return distance >= -limit and distance <= limit


func miss() -> void:
	missed = true
	canBeHit = false

func follow_strum(strum: StrumNote = strumNote) -> void:
	if !strum: return
	
	var pos = strumNote.position + get_note_offset()
	
	if strumNote._direction_radius: 
		var lerp_dir = strumNote._direction_lerp; 
		pos.x += real_distance * lerp_dir.y; 
		pos.y += real_distance * lerp_dir.x
	else: pos.y += real_distance
	
	if copyX: position.x = pos.x
	if copyY: position.y = pos.y
	if copyAlpha: modulate.a = strumNote.modulate.a * multAlpha

#Replaced in NoteSustain
func get_note_offset() -> Vector2: return Vector2(offsetX,offsetY)

func resetNote() -> void: ##Reset Note properties.
	material = null
	
	ignoreNote = false
	wasHit = false
	
	judgementTime = INF
	missed = false
	offset = Vector2.ZERO
	strumConfirm = true
	
	noAnimation = false
	splashName = &"noteSplash"

#region Updaters
func updateNote() -> void:
	distance = (strumTime - Conductor.songPositionDelayed)
	canBeHit = _can_hit(); follow_strum()

func _get_distance(): return distance * _real_note_speed

func _update_note_speed() -> void: 
	_real_note_speed = noteSpeed * 0.45 * multSpeed
	if strumNote: _real_note_speed *= (-strumNote.multSpeed) if strumNote.downscroll else strumNote.multSpeed

#endregion

#region Setters
func loadFromStyle(noteStyle: StringName) -> void:
	super(noteStyle)
	var offsets = styleData.get_offsets()
	offsetX = offsets.x; offsetY = offsets.y

func _set_note_speed(_speed: float) -> void:
	if noteSpeed == _speed: return
	noteSpeed = _speed; _update_note_speed()

func set_note_data(data: int): super(data); splashPrefix = directions[data]

func _set_distance(dist: float) -> void: distance = dist;  real_distance = _get_distance()

func set_mult_speed(_speed: float):
	if multSpeed == _speed: return
	multSpeed = _speed
	_update_note_speed() 

func _set_strum(strum: StrumNote) -> void:
	if strumNote and strumNote.mult_speed_changed.is_connected(_update_note_speed): 
		strumNote.mult_speed_changed.disconnect(_update_note_speed)
	
	strumNote = strum; if !strum: return
	hit_actions = strum.hit_actions
	if is_inside_tree(): strum.mult_speed_changed.connect(_update_note_speed); _update_note_speed()
#endregion

func has_sustains() -> bool: return sustainLength and !isSustainNote

func _on_hit() -> void: kill(); wasHit = true;

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			if !strumNote: return
			strumNote.mult_speed_changed.connect(_update_note_speed)
			_update_note_speed()
		NOTIFICATION_EXIT_TREE: if strumNote: strumNote.mult_speed_changed.disconnect(_update_note_speed)
	super(what)


##Returns a Dictionary of the note base data, that contains:[br]
##[code]t = strumTime;[/code][br]
##[code]d = data;[/code][br]
##[code]l = length;[/code][br]
##[code]gf = gfNote;[/code]
static func getInputActions(key_count: int = Conductor.songData.data.get("keyCount",4)) -> Array: 
	return ClientPrefs.data.note_keys[key_count]

static func same_note(note1: Note, note2: Note) -> bool: ##Detect if [param note1] is the same as [param note2].
	return note1 and note2 and \
	note1.strumTime == note2.strumTime and \
	note1.noteData == note2.noteData and \
	note1.mustPress == note2.mustPress and \
	note1.isSustainNote == note2.isSustainNote and \
	note1.noteType == note2.noteType
