extends Node

var items: Array[CanvasItem]


func set_parallax(node: CanvasItem, factor: Vector2):
	if !node: return
	if factor == Vector2.ONE:
		node.remove_meta(&"factor")
		items.erase(node)
		if !items: set_process(false)
	set_process(true)
	node.set_meta(&"factor",factor - Vector2.ONE)
	if !node in items: items.append(node)

func _process(_d: float) -> void:
	if !items: return
	var i = items.size()
	while i:
		i -= 1
		var item: CanvasItem = items[i]
		if !item: items.remove_at(i); continue
		var parent = item.get_parent(); if !parent: continue
		
		var pos
		if parent is FunkinScroll2D: pos = parent.scroll
		elif parent is Node2D: pos = parent.position
		else: continue
		
		var transform = item.get_transform()
		transform.origin -= pos * item.get_meta(&"factor")
		RenderingServer.canvas_item_set_transform(item.get_canvas_item(), transform)
