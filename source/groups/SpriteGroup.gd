@icon("res://icons/node2d_group.svg")
@tool
extends Node2D
class_name SpriteGroup
##A Sprite Group
##based in [url=https://api.haxeflixel.com/flixel/group/FlxGroup.html]FlxGroup[/url] 
##to be more accurate with 
##[url=https://gamebanana.com/mods/309789]Psych Engine[/url], 
##being easing to understand the code.

var members: Array
var scrollFactor: Vector2 = Vector2.ONE ##Scroll factor of this group, just works if the member is a [Sprite].



#region Add/Remove methods
##Add a [Node] to this group. 
##If [code]insertOnGame[/code], the node will be added to tree if the group is added.
func append(node: Node,insertOnGame: bool = true) -> void:
	if !node: return
	if !node in members: members.append(node);# _add_member_position(node,x,y)
	if not insertOnGame: return
	_add_obj_to_camera(node)

func _add_obj_to_camera(node: Node) -> void:
	if !node: return
	if node.get_parent(): node.reparent(self,false)
	else: add_child(node)

##Insert a [Node] in a specific order. 
func insert(at: int, node: Node) -> void:
	if !node: return
	_add_obj_to_camera(node)
	at = clampi(at,0,get_child_count())
	move_child(node,mini(at,get_child_count()-1))
	members.insert(at, node)

##Remove [Node] from the group.
func remove(node: Object) -> void:
	var i = members.find(node)
	if i != -1: remove_at(i)


func remove_at(index: int) -> void: ##Remove a [Node] using his [code]index[/code] in the group.
	var node = members.get(index); if !node: return
	if node.get_parent() == self: remove_child(node)
	members.remove_at(index)


func queue_free_members() -> void: ##Queues all members of this group. See also [method Node.queue_free].
	for i in members: i.queue_free()
	members.clear()
#endregion


#region Iter
var _iter_i: int = 0
func _iter_get(_i) -> Variant: return members[_iter_i]
func _iter_init(_i) -> bool: _iter_i = 0; return _iter_i < members.size()
func _iter_next(_i) -> bool: _iter_i += 1; return _iter_i < members.size()
func _get(property: Variant) -> Variant:
	if property is int:
		return members[property]
	return
#endregion
