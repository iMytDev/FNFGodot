shader_type canvas_item;

uniform float strength = 0.015;
uniform float space = 3.0;
uniform float frequency = 1.0;
uniform float offset = 0.0;
vec2 get_distorcion(vec2 uv){
	float uv_x = sin((uv.y - offset - TIME * frequency)*PI*space)*strength;
	uv_x += uv.x;
	return vec2(uv_x,uv.y);
}
void fragment(){
	COLOR = texture(TEXTURE,get_distorcion(UV));
}