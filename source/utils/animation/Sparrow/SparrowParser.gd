@tool
class_name Sparrow
##A Sparrow Parser.

##A [Dictionary] that stores the Sparrows created using [method loadSparrow].[br]
## If you don't want it saved, use [method _load_sparrow].
static var sparrows_loaded: Dictionary[String,Dictionary]


static var _parser: XMLParser = XMLParser.new()

##Load the data from the xml file, [param file] have to be the [b]ABSOLUTE PATH[/b].[br][br]
## Example: [codeblock]
##loadSparrow("images/Image.xml") # Wrong
##loadSparrow("C:/Users/[Your Username]/Images/images/Image.xml") # Correct
##loadSparrow(Paths.detectFileFolder("images/Image.xml"))  #Also works if the file are found.
##[/codeblock]
##OBS: This method [u]stores the loaded XML[/u] to make searching faster.
##If you don't want to reuse the already loaded sparrow, use [method _load_sparrow].
static func loadSparrow(file: String) -> Dictionary[StringName, Array]:
	var sparrow: Dictionary[StringName, Array]
	if sparrows_loaded.has(file): sparrow = sparrows_loaded[file]; if sparrow: return sparrow
	sparrow = _load_sparrow(file)
	sparrows_loaded[file] = sparrow
	return sparrow

##Load Sparrow without caching.[br]See also [method loadSparrow].
static func _load_sparrow(file_absolute: String) -> Dictionary[StringName, Array]:
	if !FileAccess.file_exists(file_absolute): return {}
	var sparrow: Dictionary[StringName, Array]
	_parser.open(file_absolute)
	while _parser.read() == OK: #Aqui começa a ler
		if _parser.get_node_type() != XMLParser.NODE_ELEMENT: continue
		var xmlName: StringName = _parser.get_named_attribute_value_safe('name')
		if !xmlName:  continue;
		xmlName = xmlName.left(-4) #< ---Isso aqui, ele remove os numeros finais da string, os "0000"
		
		var animationFrames: Array[Dictionary] = sparrow.get_or_add(
			xmlName,
			Array([],TYPE_DICTIONARY,&'',null)
		)
		
		var region_data: Rect2 = Rect2(
			_parser.get_named_attribute_value('x').to_float(),
			_parser.get_named_attribute_value('y').to_float(),
			_parser.get_named_attribute_value('width').to_float(),
			_parser.get_named_attribute_value('height').to_float()
		)
		
		var rotated = !!_parser.get_named_attribute_value_safe('rotated')
		
		
		var frameRect = Rect2(Vector2.ZERO,Vector2.ZERO)
		if _parser.has_attribute('frameX'):
			frameRect = Rect2(
				-_parser.get_named_attribute_value('frameX').to_float(),
				-_parser.get_named_attribute_value('frameY').to_float(),
				_parser.get_named_attribute_value('frameWidth').to_float(),
				_parser.get_named_attribute_value('frameHeight').to_float()
			)
			if rotated: frameRect.position = Vector2(-frameRect.position.y, frameRect.position.x)
		
		var frameData: Dictionary = {
			&"region_rect": region_data, 
			&"frameData": frameRect, 
			&"rotated": rotated
		}
		animationFrames.append(frameData)
	return sparrow
