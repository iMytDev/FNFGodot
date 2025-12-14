@tool
class_name Prefs extends Resource
##Client Preferences. 
var modsEnabled: Dictionary = {}
var modsOrder: Array
var note_keys: Dictionary = {
	1: [
		[KEY_D,KEY_LEFT]
	],
	2:[
		[KEY_F,KEY_DOWN],
		[KEY_J,KEY_UP]
	],
	3:[ 
		[KEY_D,KEY_LEFT],
		[KEY_SPACE,KEY_DOWN],
		[KEY_K,KEY_RIGHT]
	],
	4:[ 
		[KEY_D,KEY_LEFT],
		[KEY_F,KEY_DOWN],
		[KEY_J,KEY_UP],
		[KEY_K,KEY_RIGHT]
	],
	5:[ 
		[KEY_D,KEY_LEFT],
		[KEY_F,KEY_DOWN],
		[KEY_SPACE],
		[KEY_J,KEY_UP],
		[KEY_K,KEY_RIGHT]
	],
	6:[ 
		[KEY_S],
		[KEY_D],
		[KEY_F],
		[KEY_J],
		[KEY_K],
		[KEY_L]
	],
	7:[ 
		[KEY_S],
		[KEY_D],
		[KEY_F],
		[KEY_SPACE],
		[KEY_J],
		[KEY_K],
		[KEY_L]
	]
}

@export_category("Gameplay Options")
@export var splashSkin: String = 'noteSplashes/noteSplashes'
@export var arrowSkin: String ='noteSkins/NOTE_assets'
@export var noteSkin: String = 'Default'

@export var middlescroll: bool
@export var downscroll: bool


@export var playAsOpponent: bool
@export var notHitSustainWhenMiss: bool

@export_category("Combo")
@export var comboStacking: bool = true
@export var comboOffset: PackedInt64Array = PackedInt64Array([
	700,-250, #Combo Pos
	-550,-250 #Numer Pos
])

@export var miraculousRating: bool
@export var miraculousOffset: float =  25.0
@export var sickOffset: float = 45.0
@export var goodOffset: float = 130.0
@export var badOffset: float = 150.0

@export_category("Hud Options")
@export var timeBarType: StringName = &"Time Left"
@export var hideHud: bool
@export var botplay: bool

@export var splashesEnabled: bool = true
@export var opponentSplashes: bool

@export_category("Window Options")
@export var window_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
@export var fps: float = 120
var vsync_mode: DisplayServer.VSyncMode = ProjectSettings.get_setting("display/window/vsync/vsync_mode")


@export_category("Audio Options")
@export var songOffset: float = 0.0

@export_category("Visual Options")
@export_range(0.4,1.0,0.05) var sustain_alpha: float = 0.6
@export var lowQuality: bool = false

@export var shadersEnabled: bool = true
@export var flashingLights: bool = true
@export var antialiasing: bool = true
@export var fixImageBorders: bool = false

@export var camZooms: bool = true
