extends Option

var groups: Dictionary

var options_selected = []
var cur_option_group: Node
var cur_option: Node

func _init():
	super()
	type = Type.GROUP

func _ready() -> void:
	createMenuOptions()
	_show_options()
	queue_redraw()

func _draw(): draw_texture(Paths.texture('menuDesat'),Vector2.ZERO)

func createMenuOptions():
	var cur_group = self
	for i in ClientPrefs.data.get_script().get_script_property_list(): 
		var is_category: bool = i.usage & PROPERTY_USAGE_CATEGORY
		if !is_category and !i.usage & PROPERTY_USAGE_EDITOR: continue
		
		var prop_name = i.name
		var property = Option.new(prop_name)
		property.name = prop_name
		if is_category:
			cur_group = property
			property.type = Option.Type.GROUP
			var meta = get_meta(&"options")
			meta.append(property)
		else:
			var meta = cur_group.get_meta(&"options")
			meta.append(property)
	
class Option extends FunkinText:
	enum Type{
		GROUP,
		BOOL,
		FLOAT,
		INT
	}
	var type: Type
	
	func _init(option_name: StringName = &""):
		super(option_name)
		set_meta(&"options",[])
	func _show_options():
		var meta = get_meta(&"options")
		if !meta: return
		var index: int = 0
		while index < meta.size(): var i = meta[index]; add_child(i); i.position.y = 200 * index; index += 1
		
