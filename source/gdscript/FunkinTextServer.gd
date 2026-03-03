class_name FunkinTextServer extends FunkinInternal

static var textsCreated: Dictionary[StringName,Label] ##[b]Texts[/b] created using [method makeText] function.
##Creates a Text
static func makeText(tag: StringName,text: Variant = '', width: float = 500, x: float = 0, y:float = 0) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.size.x = width
	label.add_theme_constant_override(&"outline_size",8)
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.position = Vector2(x,y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if !tag: return label
	removeText(tag)
	label.name = tag
	textsCreated[tag] = label
	return label



static func setTextString(tag: Variant, text: Variant = '') -> void: ##Set the text string
	tag = FunkinProperty._find_object(tag); if tag is Label: tag.text = str(text)

##Set the color from the text
static func set_text_color(text: Variant, color: Variant) -> void:
	text = FunkinProperty._find_object(text); 
	if text is Control: text.add_theme_color_override(&"font_color",_get_color(color))


static func setTextBorder(text: Variant, border: float, color: Color = Color.BLACK) -> void: ##Set Text Border
	text = FunkinProperty._find_object(text); 
	if text is Control:
		text.add_theme_color_override(&"font_outline_color",color)
		text.add_theme_constant_override(&"outline_size",border)

##Set the Font of the Text
static func set_text_font(text: Variant, font: Variant = 'vcr.ttf') -> void:
	text = FunkinProperty._find_object(text); 
	if text is Control:
		font = _find_font(font); if !font: return
		text.add_theme_font_override(&'font',font)

static func get_text_font(text: Variant) -> FontFile:
	text = FunkinProperty._find_object(text); 
	if text is Control: return text.get_theme_font(&"font")
	return ThemeDB.fallback_font

static func _find_font(font: Variant) -> Font: return font if font is Font else Paths.font(font)

##Set the Text Alignment
static func setTextAlignment(tag: Variant, alignmentHorizontal: StringName = &'left', alignmentVertical: StringName = &'') -> void:
	var obj = FunkinProperty._find_object(tag); if !obj is Label: return
	
	match alignmentHorizontal:
		&'left': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		&'center': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		&'right': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		&'fill': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	match alignmentVertical:
		&'left': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		&'center': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		&'right': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		&'fill': obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	
	match alignmentVertical:
		&'top': obj.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		&'center': obj.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		&'bottom': obj.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		&'fill': obj.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		


static func set_text_size(text: Variant, size: float = 15) -> void: ##Set the font's size of the Text
	text = FunkinProperty._find_object(text); 
	if text is Control: text.add_theme_font_size_override(&"font_size",size)


static func addText(text: Variant, front: bool = false, camera: StringName = &"hud") -> void: ##Add a text created using [method makeText] to scene
	text = FunkinProperty._find_object(text);
	
	var cam = FunkinProperty.get_property(camera); if !cam: return
	if cam is FunkinCamera2D: 
		cam.add(text,front)
	else:
		cam.add_child(text)

##Remove Text from the game, if [code]delete[/code] is [code]true[/code], the text will be removed from the memory.
static func removeText(text: Variant,delete: bool = false) -> void:
	text = FunkinProperty._find_object(text); if !text: return
	if delete: 
		textsCreated.erase(text.name); 
		text.queue_free()
	else: 
		var parent = text.get_parent(); 
		if parent: parent.remove_child(text)

static func textsExits(tag: String) -> bool: ##Check if the Text as created
	return textsCreated.has(tag) 
