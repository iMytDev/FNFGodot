shader_type spatial;
render_mode unshaded;

uniform sampler2D clouds_texture: repeat_disable;
uniform vec4 clouds_modulate: source_color = vec4(1.0);
group_uniforms uv;
uniform vec2 speed;

uniform bool uv_repeat = true;
uniform bool uv_mirror_x = true;
uniform bool uv_mirror_y;
uniform vec2 uv_scale = vec2(1.0);
uniform vec2 uv_repeat_offset;

vec2 repeat_mirrored(vec2 uv){
	uv = mod(uv,vec2(1.0 + uv_repeat_offset) * 2.0);
	vec2 uv_floor = floor(uv);
	return abs(uv - uv_floor * 2.0);
}
void fragment() {
	vec2 uv = (UV * uv_scale) + (vec2(TIME) * speed * 0.01);
	if(uv_repeat){
		vec2 uv_mirrored = repeat_mirrored(uv);
		if(uv_mirror_x) uv.x = uv_mirrored.x; 
		else uv.x = mod(uv.x,1.0 + uv_repeat_offset.x);
		
		if(uv_mirror_y) uv.y = uv_mirrored.y; 
		else uv.y = mod(uv.y,1.0 + uv_repeat_offset.y);
	}
	vec4 tex = texture(clouds_texture,uv);
	ALBEDO = tex.rgb * clouds_modulate.rgb;
	ALPHA = tex.a * clouds_modulate.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
