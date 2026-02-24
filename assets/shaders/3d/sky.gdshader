shader_type sky;
render_mode use_debanding;

uniform float time_offset: hint_range(-1.0, 1.0, 0.05) = 0.0;
uniform float exposure : hint_range(0, 128) = 1.0;

group_uniforms Day;
uniform vec3 day_top_color : source_color = vec3(0.1, 0.5, 1.0);
uniform vec3 day_horizon_color : source_color = vec3(0.8, 1.0, 0.9);

group_uniforms Sunset;
uniform bool sunset = true;
uniform vec3 sunset_color: source_color = vec3(1.0,0.5,0.0);
uniform float sunset_start = 0.0;

group_uniforms Sun;
uniform float inv_sky_curve : hint_range(1, 100) = 4.0;
uniform float inv_ground_curve : hint_range(1, 100) = 30.0;
uniform float sun_angle_max = 0.877;
uniform float inv_sun_curve : hint_range(1, 100) = 22.78;

uniform sampler2D sky_cover: filter_linear, source_color, hint_default_black;

//Clouds Properties
group_uniforms Clouds;
uniform bool clouds = true;
uniform float clouds_offset = -0.1;
uniform vec2 cloud_direction = vec2(3.0,9.0);
uniform float clouds_wave_strength = 0.01;
uniform vec2 cloud_scale = vec2(1.0);
uniform sampler2D cloud_texture;

uniform float clouds2_offset = -0.1;
uniform vec2 cloud2_direction = vec2(3.0,9.0);
uniform vec2 cloud2_scale = vec2(1.0);
uniform sampler2D cloud2_texture;

//Night Color
group_uniforms Night;
uniform bool stars = true;
uniform sampler2D stars_noise: filter_nearest;
uniform vec3 night_top_color: source_color;
uniform vec3 night_bottom_color: source_color;
float get_sun_dot(
	vec3 eye_dir, 
	vec3 light_dir, 
	float light_size, 
	float light_energy
){
	float sun_angle = dot(light_dir, eye_dir);
	float sun_size = cos(light_size);
	if (sun_angle > sun_size) return light_energy;
	else if (sun_angle > sun_angle_max) {
		float c2 = (sun_size - sun_angle) / (sun_size - sun_angle_max);
		return light_energy * clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0);
	}
	return 0.0;
}

float get_sun_coner_mix_value(
	vec3 sun_direction, 
	vec3 eye_dir,
	float size
){
	float dist_smooth = smoothstep(0.0,1.0,distance(eye_dir,sun_direction));
	float sun_dot = dot(eye_dir, sun_direction);
	sun_dot = smoothstep(sun_direction.x,1.0,sun_dot);
	float mix_value = sun_dot;
	return clamp(mix_value,0.0,1.0);
}

float get_day_time(vec3 sun_direction){
	return 1.0 - (sun_direction.y * 0.5 + 0.5 + time_offset);
}

void sky() {
	vec3 angle = EYEDIR;
	vec3 sun_color = vec3(0.0);
	float energy = 1.0;
	float sun_y = 0.5;
	float size = 1.0;
	
	if (LIGHT0_ENABLED) {
		sun_color = LIGHT0_COLOR * get_sun_dot(EYEDIR,LIGHT0_DIRECTION,LIGHT0_SIZE,LIGHT0_ENERGY);
		angle = LIGHT0_DIRECTION;
		size = LIGHT0_SIZE;
		energy = LIGHT0_ENERGY;
	}
	else sun_color = vec3(get_sun_dot(EYEDIR,vec3(0.0,sun_y,0.0),0.5,1.0));
	
	if (LIGHT1_ENABLED) {
		sun_color += LIGHT1_COLOR*get_sun_dot(EYEDIR,LIGHT1_DIRECTION,LIGHT1_SIZE,LIGHT1_ENERGY);
	}
	
	
	float dt = get_day_time(angle);
	float dts = smoothstep(0.0,0.65,dt);
	float y_pow = clamp(pow(1.0 - EYEDIR.y, inv_sky_curve),0.0,1.0);
	
	
	
	vec3 top_col = mix(day_top_color, night_top_color, smoothstep(0.0,0.65,dt));
	vec3 bottom_col = mix(day_horizon_color, night_bottom_color, dts);
	
	vec3 sky_col = mix(top_col,bottom_col,y_pow);
	
	if(sunset){
		float mix_coner = get_sun_coner_mix_value(angle, EYEDIR, size);
		sky_col = mix(
			sky_col,
			sunset_color,
			mix_coner * dts
		);
	}
	
	COLOR = (sky_col + sun_color) * exposure;
	
	if(clouds){
		float cloud_y = EYEDIR.y - clouds_offset;
		if(cloud_y >= 0.15){
			float time = TIME*0.005;
			vec2 uv = EYEDIR.xz / cloud_y;
			vec2 wave = vec2(
				cos(time + uv.y * 20.0),
				sin(time + uv.x * 20.0)
			);
			wave *= clouds_wave_strength;
			uv += wave;
			vec4 clouds_col = texture(cloud_texture,uv * cloud_scale + time*cloud_direction);
			clouds_col *= max(0.005,1.0 - dts);
			COLOR += max(vec3(0.0),clouds_col.rgb - COLOR);
		}
	}

	if(stars){
		vec2 uv = SKY_COORDS * 10.0;
		vec4 stars_tex = texture(stars_noise,uv);
		stars_tex *= dt;
		COLOR += max(vec3(0.0),stars_tex.rgb - COLOR);
	}
}
