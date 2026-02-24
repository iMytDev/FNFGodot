class_name FunkinShadersServer extends FunkinInternal
static var shadersCreated: Dictionary[StringName,ShaderMaterial] ##[b]Shaders[/b] created using [method initShader] function.

##Create Shader using tags, making it possible to create several shaders from the same material;[br][br]
##Example: [codeblock]
##initShader('shader1','Chrom');
##initShader('shader2','Chrom');
##setShaderFloat('shader2','strength',1.0);
##[/codeblock][br]
##[b]OBS:[/b] if [code]obrigatory[/code], the shader will be started 
##even [code]shadersEnabled[/code] is false.
static func init(shader: String, tag: StringName = &'', obrigatory: bool = false) -> ShaderMaterial:
	if !obrigatory and !FunkinGD.shadersEnabled: return
	if !tag: tag = shader
	if tag in shadersCreated and shadersCreated[tag].shader.resource_name == shader: 
		return shadersCreated[tag]
	
	var shader_material: ShaderMaterial = Paths.loadShader(shader)
	if !shader_material: return
	shadersCreated[tag] = shader_material
	FunkinGD.callOnScripts(&'onLoadShader', shader, shader_material,tag)
	return shader_material
	
##Add [Material] to a [code]camera[/code], [code]shader[/code] can be a [String] or a [Array].[br][br]
##[b]OBS:[/b] If the [code]shader[/code] was not started using [method initShader], this function will call automatically.
##[br][br]Example of code:[codeblock]
##var shader_material1 = ShaderMaterial.new()
##var shader_material2 = ShaderMaterial.new()
##addShaderCamera('game',shader_material1)
##addShaderCamera('game',shader_material2)
###or
##addShaderCamera('game',[shader_material1,shader_material2])
###or
##addShaderCamera('game',['ChromaticAberration',shader_material2])
##[/codeblock][br]
##If you want to add the same shader in more cams:
##[codeblock]
##addShaderCamera(['game','hud'],shader_material2)
##[/codeblock]
##[b]Note:[/b] The same works for [method removeShaderCamera].
##[br][br]See also [method setSpriteShader].
static func add_shaders_to_camera(camera: Variant, shaders: Array):
	_check_shaders_array(shaders)
	if camera is Array: for i in camera: for s in shaders: _append_shader_to_camera(i, s)
	else: for i in shaders: _append_shader_to_camera(camera, i)

static func camera_set_shaders(camera: Variant, shaders: Array):
	_check_shaders_array(shaders)
	if camera is Array: for i in camera: i.set_filters(shaders)
	else: camera.set_filters(shaders)

static func _append_shader_to_camera(camera: Variant, shader: ShaderMaterial):
	camera = FunkinCameraServer.camera_get(camera)
	if camera: camera.controller.add_filter(shader)




##Remove shader from the camera, [code]shader[/code] can be a [String] or a [Array].
##[br]See also [method addShaderCamera].
static func remove_camera_shader(camera: Variant, shader: Variant) -> void:
	var cam = FunkinCameraServer.camera_get(camera); if !cam: return
	shader = find_shader_material(shader); if !shader: return
	cam.removeFilter(shader)

#region Shader Values Methods
static func setShaderParameter(shader: Variant, parameter: String, value: Variant): 
	shader = find_shader_material(shader); 
	if shader: shader.set_shader_parameter(parameter,value)

static func addShaderFloat(shader: Variant, parameter: String, value: float): ##Add [code]value[/code] to a [u][float] parameter[/u] of a [code]shader[/code] created using [method initShader].
	shader = find_shader_material(shader); if !shader: return
	var vars = shader.get_shader_parameter(parameter); if vars == null: vars = 0.0
	shader.set_shader_parameter(parameter,vars+value)

static func getShaderParameter(shader: Variant, shaderVar: String) -> Variant: 
	shader = find_shader_material(shader); 
	return shader.get_shader_parameter(shaderVar) if shader else null
#endregion

static func setBlendMode(object: Variant, blend: String) -> void: ##Sets Object Blend mode, can be: [code]add,subtract,mix[/code]
	object = FunkinProperty._find_object(object); if !object is CanvasItem: return
	object.material = ShaderUtils.get_blend(blend)
#endregion

static func _check_shaders_array(shaders: Array) -> void:
	var index: int = shaders.size()
	while index:
		index -= 1
		var s = shaders[index]
		if s is String: shaders[index] = find_shader_material(s)
	
static func find_shader_material(shader: Variant) -> ShaderMaterial:
	if !shader or shader is ShaderMaterial: return shader
	var material = shadersCreated.get(shader); if material: return material
	material = FunkinProperty._find_object(shader)
	return material.get(&'material') if material else null

static func clear() -> void: shadersCreated.clear()
