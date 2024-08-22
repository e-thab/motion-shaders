shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
global uniform sampler2D noise;
global uniform sampler2D last_frame;

void fragment() {
	// Maybe try adding another viewport/shader layer that 'keeps track' of switched pixels by copying
	// previous frame pixels from BackBufferCopy?
	//vec2 coords = vec2(UV.x, UV.y);
	
	//Get original fragment color (RGBA)
	vec4 c = textureLod(TEXTURE, SCREEN_UV, 0.0).rgba;
	
	
	//Invert RGB only (not A)
	vec3 changed = max(
		texture(last_frame, SCREEN_UV).rgb - texture(screen_texture, SCREEN_UV).rgb,
		vec3(0.0, 0.0, 0.0)
	);
	
	c.rgb = abs(changed - c.rgb);
	COLOR = c;
	
	
	//COLOR = vec4(255.0, 0.0, 0.0, 1.0);
	//vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	//if (c.r > 0.0) {
		//
		////COLOR = vec4(255.0, 0.0, 0.0, 1.0);
	//}
}

//void fragment() {
	//vec2 uv = SCREEN_UV;
	//uv.x += sin(uv.y * frequency + TIME) * depth;
	//uv.x = clamp(uv.x, 0.0, 1.0);
	//vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
//
	//COLOR.rgb = c;
//}
