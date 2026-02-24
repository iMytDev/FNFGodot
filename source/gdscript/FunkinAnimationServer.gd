class_name FunkinAnimationServer extends FunkinInternal

##Add Animation Frames for the [param object], useful if you are creating custom [Icon]s.
static func add_animation(object: Variant, animName: StringName, frames: Array = [], frameRate: float = 24, loop: bool = false) -> AnimationData:
	object = FunkinProperty._find_object(object); if !object or !object.get('animation'): return 
	return object.animation.addFrameAnim(animName,frames,frameRate,loop)

##Add animation to a [Sprite] using the prefix of his image.
static func add_animation_by_prefix(object: Variant, animName: StringName, xmlAnim: StringName, frameRate: float = 24, loop: bool = false, indices: Variant = null) -> AnimationData:
	object = FunkinProperty._find_object(object); if !object or !object.get('animation'): return
	if indices: 
		if indices is String: indices = AnimationService.get_indices_by_str(indices)
		return object.animation.add_animation_by_prefix(animName,xmlAnim,frameRate, loop, indices)
	return object.animation.add_animation_by_prefix(animName,xmlAnim,frameRate, loop)

##Makes the [param object] play a animation, if exists. If [param force] and the current anim as the same name, that anim will be restarted.
static func play_anim(object: Variant, anim: StringName, force: bool = false, reverse: bool = false) -> void:
	object = FunkinProperty._find_object(object); if not (object is FunkinSprite2D and object.animation): return
	if reverse: object.animation.play_reverse(anim,force)
	else: object.animation.play(anim,force)

##Add offset for the animation of the sprite.
static func add_offset(object: Variant, anim: StringName, offsetX: float, offsetY: float)  -> void:
	var obj = FunkinProperty._find_object(object);
	if object: 
		var animation: Anim = obj.get('animation')
		if !animation: debug_message("Error on add animation offset: "+obj.name+" are not animated.")
		animation.add_animation_offset(anim,Vector2(offsetX,offsetY))
		return
	
	if obj is String: debug_message("Error on add animation offset: "+object.name+" don't exists.")
	else: debug_message("Error on add animation offset: Sprite is not valid.")
	
