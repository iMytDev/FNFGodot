shader_type canvas_item;

uniform float strength : hint_range(0.0, 5.0) = 0.3;

void fragment() {
	vec2 uv_sub = UV - 0.5;
	float dist = abs(uv_sub.x);
	float factor = 1.0 + (smoothstep(0.0,1.0,dist) * strength);

	COLOR = texture(TEXTURE, uv_sub / factor + 0.5);
}
