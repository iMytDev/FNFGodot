@tool
class_name Prefs extends Resource ##Client Preferences.
var modsOrder: Array
var note_keys: Dictionary[int,Array] = {
	1: [
		PackedInt32Array([KEY_D,KEY_LEFT])
	],
	2:[
		PackedInt32Array([KEY_F,KEY_DOWN]),
		PackedInt32Array([KEY_J,KEY_UP])
	],
	3:[ 
		PackedInt32Array([KEY_D,KEY_LEFT]),
		PackedInt32Array([KEY_SPACE,KEY_DOWN]),
		PackedInt32Array([KEY_K,KEY_RIGHT])
	],
	4:[ 
		PackedInt32Array([KEY_D,KEY_LEFT]),
		PackedInt32Array([KEY_F,KEY_DOWN]),
		PackedInt32Array([KEY_J,KEY_UP]),
		PackedInt32Array([KEY_K,KEY_RIGHT])
	],
	5:[ 
		PackedInt32Array([KEY_D,KEY_LEFT]),
		PackedInt32Array([KEY_F,KEY_DOWN]),
		PackedInt32Array([KEY_SPACE]),
		PackedInt32Array([KEY_J,KEY_UP]),
		PackedInt32Array([KEY_K,KEY_RIGHT])
	],
	6:[ 
		PackedInt32Array([KEY_S]),
		PackedInt32Array([KEY_D]),
		PackedInt32Array([KEY_F]),
		PackedInt32Array([KEY_J]),
		PackedInt32Array([KEY_K]),
		PackedInt32Array([KEY_L])
	],
	7:[ 
		PackedInt32Array([KEY_S]),
		PackedInt32Array([KEY_D]),
		PackedInt32Array([KEY_F]),
		PackedInt32Array([KEY_SPACE]),
		PackedInt32Array([KEY_J]),
		PackedInt32Array([KEY_K]),
		PackedInt32Array([KEY_L])
	]
}

@export_category("Gameplay Options")
@export var middlescroll: bool
@export var downscroll: bool


@export var playAsOpponent: bool
@export var notHitSustainWhenMiss: bool

@export_category("Combo")
@export var comboStacking: bool = true
@export var comboOffset: PackedInt64Array = PackedInt64Array([
	700,-250,
	-550,-250
])

@export var miraculousRating: bool
@export var miraculousOffset: float =  25.0
@export var sickOffset: float = 45.0
@export var goodOffset: float = 130.0
@export var badOffset: float = 150.0
@export var note_hit_time: float = 200.0

@export_category("Hud Options")
var timeBarType: StringName = &"Disabled"
@export var hideHud: bool:
	set(val): hideHud = val;
@export var botplay: bool = false

@export var splashesEnabled: bool = true
@export var opponentSplashes: bool

@export_category("Window Options")
@export var window_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
@export var fps: int = 240:
	set(val): Engine.max_fps = val; fps = val
var vsync_mode: DisplayServer.VSyncMode = ProjectSettings.get_setting("display/window/vsync/vsync_mode")


@export_category("Audio Options")
@export var songOffset: float

@export_category("Visual Options")
@export_range(0.4,1.0,0.05) var sustain_alpha: float = 0.6
@export var lowQuality: bool = false

@export var shadersEnabled: bool = true
@export var flashingLights: bool = true
@export var antialiasing: bool = true
@export var fixImageBorders: bool = false

@export var camZooms: bool = true
