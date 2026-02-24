@tool
class_name FreeplaySection extends Resource
@export var title: String
@export var mod_icon: Texture
@export var bg: Texture
@export var songs: Array[SongData]:
	set(val):
		songs = val; 
		if Engine.is_editor_hint(): for i in val: i._editor_mode = i.EditorMode.FREEPLAY
		#else: for i in val: i._editor_mode = i.EditorMode.NONE
	
