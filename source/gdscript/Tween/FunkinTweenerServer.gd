class_name FunkinTweenerServer extends FunkinInternal

static var tweensCreated: Dictionary[StringName,RefCounted] ##[b][Tween][/b] created using [method startTween] function.

##Start Tween. Similar to [method createTween].[br]
##[b]OBS:[/b] if [param time] is [code]0.0[/code], this will cause the function to set the values, without any tween.
static func create_tween_safe(object: Variant, what: Dictionary,time: Variant = 1.0, easing: StringName = &'', tag: StringName = &"") -> FunkinTweenerObject:
	if object is String or object is StringName: object = _get_object_tweener(object)
	if not object is Object: return
	
	#Verify if the property exists
	for p in what:
		if _property_exists(p, object): continue
		var alt = FunkinProperty.alternative_variables.get(p); 
		if alt: what[alt] = what[p]
		what.erase(p)
	
	if !what: return
	if time: return create_tween(object,what,float(time),easing, tag)
	
	for i in what: 
		if i is NodePath or i.contains(":"): object.set_indexed(i,what[i])
		else: object.set(i,what[i])
	return

##Create a Tween Interpolation, see more about in [method TweenService.createTween]
static func create_tween(object: Variant, what: Dictionary, time: Variant, easing: StringName = &'', tag: StringName = &""):
	object = FunkinProperty._find_object(object); 
	var tween = TweenService.create_object_tween(object,what,time,easing); 
	tween.bind_node = object if object is Node else game
	if tag: _insert_tween(tag,tween)
	return tween

##Create a Tween Method, similar to [Tween.tween_method]
static func create_tween_method(from: Variant, to: Variant, time: Variant, ease: String, method: Callable, tag: StringName = &"") -> FunkinTweenerMethod:
	var tween = TweenService.create_tween_method(method,from,to,time,ease)
	tween.bind_node = game
	if tag: _insert_tween(tag, tween)
	return tween

static func is_tween_running(tag: StringName) -> bool: return tag in tweensCreated

static func create_tween_shader(shader: Variant, parameter: Variant, value: Variant, time: Variant, easing: StringName = &"", tag: StringName = &"") -> FunkinTweenerMethod:
	var shader_material = FunkinShadersServer.find_shader_material(shader)
	var init_val = shader_material.get_shader_parameter(parameter)
	if init_val == null: init_val = MathUtils.get_new_value(typeof(value))
	var tween: FunkinTweenerMethod = TweenService.create_tween_method(
		func(val): 
			shader_material.set_shader_parameter(parameter,val),
		init_val,
		value,
		time, 
		easing
	)
	if tag: _insert_tween(tag, tween)
	return tween

static func _insert_tween(tag: StringName, tween: FunkinTweener):
	cancel_tween(tag); 
	tween.finished.connect(_tween_completed.bind(tag),CONNECT_ONE_SHOT)
	tweensCreated[tag] = tween

static func cancel_tween(tag: String) -> void: ##Cancel the Tween. See also [method startTween].
	var tween = tweensCreated.get(tag); 
	if !tween: return
	TweenService.tweens_to_update.erase(tween)
	tweensCreated.erase(tag)

static func _get_object_tweener(object: String):
	var split = FunkinProperty._get_property_split(object)
	var obj = split[0]
	if !obj: return
	#if split[1]: 
		#var split_join = ":".join(split[1]); 
		#for i in what.keys(): DictUtils.rename_key(what,i,NodePath(split_join+':'+i))
	return obj

static func _property_exists(property: Variant, object: Object) -> bool:
	if property is NodePath: return object.get_indexed(property) != null
	elif property is StringName: return object.get(property) != null
	elif property is String: return object.get(property) != null or property.contains(':') and object.get_indexed(property) != null
	return false
static func _tween_completed(tag: StringName): FunkinGD.callOnScripts(&'onTweenCompleted', tag); tweensCreated.erase(tag)

##Do Tween for a [ShaderMaterial].[br][br]
##[code]shader[/code] can be a [ShaderMaterial] or a tag([String]) used in [method initShader].
##Example of Code:[codeblock]
##var shader_material: ShaderMaterial = Paths.loadShader('ChromaticAbberration')
##setShaderFloat(shader_material,'strength',0.005)
##doShaderTween(shader_material,'strength',0.0,0.2,&'','chrom_tag')
##
##initShader('ChromaticAbberation','chrom')
##setShaderFloat('chrom','strength',0.01)
##doShaderTween('chrom','strength',0.0,0.2,&'','chrom_tag')[/codeblock]
static func doShaderTween(shader: Variant, parameter: StringName, value: Variant, time: float, ease: StringName = &'', tag: StringName = '') -> FunkinTweenerMethod:
	var material: ShaderMaterial = FunkinShadersServer.find_shader_material(shader); 
	print(material)
	if !material: return
	if !time: material.set_shader_parameter(parameter,value); return
	var tween = TweenService.tween_shader(material,parameter,value,time,ease)
	tween.bind_node = game
	
	if !tag and shader is String: tag = 'shader'+shader+parameter
	if tag: _insert_tween(tag, tween)
	return tween

static func doShadersTween(shaders: Array, parameter: StringName, value: Variant, time: float, ease: StringName = &'') -> Array[FunkinTweenerMethod]:
	var tweens: Array[FunkinTweenerMethod]; for i in shaders: tweens.append(doShaderTween(i,parameter,value,time,ease))
	return tweens


#endregion
static func clear(absolute: bool) -> void:
	if absolute: for i in tweensCreated: var t = tweensCreated[i]; if t: t.stop()
	tweensCreated.clear()
