class_name ColorUtils extends Object

static func array_to_color(array, divided_by_255: bool = false) -> Color:
	if !array: return Color.WHITE
	if divided_by_255:
		match array.size():
			1: return Color(array[0]/255.0,array[0]/255.0,array[0]/255.0)
			2: return Color(array[0]/255.0,array[1]/255.0,0.0)
			3: return Color(array[0]/255.0,array[1]/255.0,array[2]/255.0)
			_: return Color(array[0]/255.0,array[1]/255.0,array[2]/255.0,array[3]/255.0)
		
	match array.size():
		1: return Color(array[0],array[0],array[0])
		2: return Color(array[0],array[1],0.0)
		3: return Color(array[0],array[1],array[2])
		_: return Color(array[0],array[1],array[2],array[3])
