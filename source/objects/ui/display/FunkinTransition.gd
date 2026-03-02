@abstract
class_name FunkinTransition extends Node2D

signal finished_start()
signal finished_end()
func _init() -> void:
	name = &'Transition'
	z_index = 1

@abstract func start_trans(auto_exit: bool = true)
@abstract func remove_trans(auto_delete: bool = true)

static func create_transition(at: Node = Global.root) -> FunkinTransition:
	if !at: 
		FunkinGD.debug_error('Error on "do_transition": "node" is invalid.'); 
		return
	
	var script = FunkinGD.loadScript("scripts/display/Transition.gd")
	if !script: 
		FunkinGD.debug_error('Error on "do_transition": "node" is invalid.');
		return;
	script = script.new()
	at.add_child(script)
	return script
