shader_type canvas_item;

uniform vec2 light_pos = vec2(0.5, 0.2);
uniform float density = 0.8;
uniform float weight = 0.6;
uniform float decay = 0.92;
uniform float exposure = 1.0;
uniform int samples = 64;

uniform sampler2D screen_texture: hint_screen_texture;
void fragment() {
    vec2 delta = (UV - light_pos) * density / float(samples);

    vec3 result = vec3(0.0);
    float illumination = 1.0;

    vec2 coord = UV;

    for (int i = 0; i < samples; i++) {
        coord -= delta - vec2(cos(TIME)*TEXTURE_PIXEL_SIZE.x*float(i),0.0);
        vec3 col = texture(TEXTURE, coord).rgb;

        float lum = dot(col, vec3(0.299, 0.587, 0.114));
        lum = smoothstep(0.2, 1.0, lum);

        result += col * lum * illumination * weight;
        illumination *= decay;
    }

    COLOR = vec4(result * exposure, 1.0);
}
