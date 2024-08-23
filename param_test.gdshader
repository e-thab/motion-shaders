shader_type canvas_item;

global uniform sampler2D noise;
global uniform sampler2D last_frame;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 RED = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	// Maybe try adding another viewport/shader layer that 'keeps track' of switched pixels by copying
	// previous frame pixels from BackBufferCopy?
	//vec2 coords = vec2(UV.x, UV.y);

	vec4 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgba;
	vec4 last_color = textureLod(last_frame, SCREEN_UV, 0.0).rgba;

	if (screen_color.r > 0.0) {
		// White pixel rendered from stage: invert
		//if (last_color.r > 0.0) {
			//COLOR = BLACK;
		//} else {
			//COLOR = WHITE;
		//}
		COLOR = RED;
	} else {
		COLOR = last_color;
		//COLOR = BLACK;
	}

	////Get original fragment color (RGBA)
	//vec4 color = textureLod(TEXTURE, SCREEN_UV, 0.0).rgba;
//
	////Invert RGB only (not A)
	//vec3 changed = max(
		//texture(last_frame, SCREEN_UV).rgb - texture(screen_texture, SCREEN_UV).rgb,
		//vec3(0.0, 0.0, 0.0)
	//);
//
	//color.rgb = abs(changed - color.rgb);
	//COLOR = color;
}
