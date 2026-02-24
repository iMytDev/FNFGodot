class_name FunkinGroups extends FunkinInternal
static var groups: Dictionary[StringName, SpriteGroup]

static func create_group(tag: StringName) -> SpriteGroup:
	var group = groups.get(tag); if group: return group
	group = SpriteGroup.new()
	groups[tag] = group
	return group

static func add_to_group(object: Variant, group: Variant, at: int = -1) -> void:
	object = FunkinProperty._find_object(object)
	if !object: return
	
	if group is String: group = FunkinProperty._find_object(group)
	if !group is Array and !group is SpriteGroup: return
	
	if at != -1: group.insert(at,object); return
	group.append(object)

static func remove_from_group_at(group: Variant, index: int):
	if group is String: group = FunkinProperty.get_property(group); if !group: return
	if group is SpriteGroup or group is Array: group.remove_at(index)

static func clear(absolute: bool = false):
	if absolute: for i in groups: groups[i].queue_free()
	groups.clear()
