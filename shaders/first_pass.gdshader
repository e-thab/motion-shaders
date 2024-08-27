shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

void fragment() {
	// Maybe try adding another viewport/shader layer that 'keeps track' of switched pixels by copying
	// previous frame pixels from BackBufferCopy?
	COLOR = vec4(255.0, 0.0, 0.0, 0.5);
	
	vec3 c = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;
	
	
}

//void fragment() {
	//vec2 uv = SCREEN_UV;
	//uv.x += sin(uv.y * frequency + TIME) * depth;
	//uv.x = clamp(uv.x, 0.0, 1.0);
	//vec3 c = textureLod(screen_texture, uv, 0.0).rgb;
//
	//COLOR.rgb = c;
//}
