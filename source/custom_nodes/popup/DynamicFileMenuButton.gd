@icon("res://icons/DynamicMenuButton.svg")
class_name DynamicFileMenuButton extends MenuButton
@export_dir var dir_to_look: String
@export var filters: PackedStringArray
@export var show_with_extenstion: bool = false
@onready var popup: PopupMenu = get_popup()

func _init(): flat = false
func _ready() -> void: _refresh()
func _refresh(): 
	if !dir_to_look: return
	if !dir_to_look.ends_with("/"): dir_to_look += '/'
	popup.clear()
	add_items_from_dir(popup,dir_to_look,filters,show_with_extenstion)

static func add_items_from_dir(popup: PopupMenu, dir: String, filters: Variant = '', with_extension: bool = false) -> void:
	var last_mod: String
	var files_find: PackedStringArray
	var min_size: int
	for i in PathsDir.get_files_at(dir,true,filters,with_extension):
		var file = i.get_file()
		if file in files_find: continue
		
		var mod: String = PathsDir.get_mod_folder(i)
		if !mod: mod = Paths.game_name
		
		if last_mod != mod:
			min_size = maxi(min_size,int(popup.get_theme_font(&'font_separator').get_string_size(mod).x)) 
			popup.add_separator(mod); last_mod = mod
		files_find.append(file)
		popup.add_item(file)
	
	min_size += 100
	popup.visibility_changed.connect(func():
		if !popup.visible: return
		popup.min_size.x = min_size
		popup.size.x = min_size
	)
