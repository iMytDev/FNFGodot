shader_type spatial;
uniform sampler2D screen_texture: hint_screen_texture;
uniform vec4 rain_constrast: source_color = vec4(0.15,0.15,0.15,1.0);

void fragment() {
	vec4 screen_col = texture(screen_texture,SCREEN_UV);
	if(screen_col.a < 0.2) discard;
	vec2 tex_size = vec2(textureSize(screen_texture,0));
	vec2 uv_offset = 1.0/tex_size;
	uv_offset.y *= cos(UV.x*5.)*5.0;
	vec2 screen_position = tex_size * SCREEN_UV/tex_size;
	ALBEDO.rgb = texture(screen_texture,SCREEN_UV + uv_offset).rgb + rain_constrast.rgb;
	ALPHA = rain_constrast.a;
}