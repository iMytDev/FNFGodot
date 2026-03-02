extends Node
const Transition = preload("uid://dkv13shj47jyv")

signal on_scene_changed()

var is_transiting: bool = false

##Swap the Tree for a new [Node]. [br][br]
##[param newTree] can be a [Node], [PackedScene], [GDScript] or a [String] as a file path.
func change_scene(newTree: Variant, transition: bool = true) -> void:
	if !newTree: push_error('change_scene(): Parameter "newTree" is null.'); return
	
	if transition:
		if is_transiting: return
		is_transiting = true
		var trans = FunkinTransition.create_transition()
		if trans: 
			trans.start_trans().finished.connect(_change_scene.bind(newTree))
			return
	_change_scene(newTree)

func _change_scene(node: Variant):
	is_transiting = false
	on_scene_changed.emit()
	node = _create_node(node)
	var tree = get_tree()
	if tree.current_scene: tree.current_scene.queue_free()
	get_tree().root.add_child(node)
	tree.current_scene = node

func _create_node(value: Variant):
	if value is String: return load(value)
	if value is GDScript: return value.new()
	elif value is PackedScene: return value.instantiate()
	return value
