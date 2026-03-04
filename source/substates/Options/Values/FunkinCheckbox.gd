extends FunkinAnimatedSprite2D
##A Check Box Class.
##
##A Example of code using a [Dictionary]: [codeblock]
##var data = {'enable': false}
##var checkBox = CheckBoxSprite.new()
##
##checkBox.object_to_set = data
##checkBox.variable = 'enable'
##checkBox.value = true #Automatically changes the data.enable.
##[/codeblock]
##A Example of code using a [Array]: [codeblock]
##var data = ['Object',Vector2.ZERO,false]
##var checkBox = CheckBoxSprite.new()
##
##checkBox.object_to_set = data
##checkBox.variable = 2 #The array index.
##checkBox.value = true #Changes data[2] to true.
##[/codeblock]

signal toggled(toogle_on: bool)
##Boolean.
var value: bool:
	set(boolean):
		if boolean == value: return
		value = boolean
		if value: animation.play(&'selection',true)
		else: animation.play_reverse(&'selection',true)
		toggled.emit(value)


func _init():
	super('checkboxThingie')
	animation.animation_finished.connect(func(anim):
		if anim == &'selection': 
			animation.play(&'unselected' if animation.reversed else &'selected')
	)
	animation.add_animation_by_prefix(&'unselected',&'Check Box unselected')
	animation.add_animation_offset(&"unselected",Vector2(10,40))
	animation.add_animation_by_prefix(&'selection',&'Check Box selecting animation')
	animation.add_animation_offset(&"selection",Vector2(15.0,95))
	animation.add_animation_by_prefix(&'selected',&'Check Box selected')
	animation.add_animation_offset(&"selected",Vector2(15.0,95))
	
	animation.frame = animation.maxFrames-1
