extends Resource

var name: StringName
var object: Variant
var property: StringName
var options: Dictionary = {}

func _init(_name: StringName, _object: Variant, _property: StringName, _options: Dictionary = {}) -> void:
	name = _name
	object = _object
	property = _property 
	options = _options
