shader_type canvas_item;

global uniform sampler2D last_frame;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform vec4 RED = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 screen_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgba;
	vec4 last_color = textureLod(last_frame, SCREEN_UV, 0.0).rgba;
	
	if (last_color == screen_color) {
		COLOR = BLACK;
	} else if (last_color.g == 0.0 && screen_color.g == 1.0) {
		COLOR = WHITE;
	} else {
		COLOR = BLACK;
	}
	
	//if (last_color.g == 1.0 && screen_color.r > 0.1) {
		//COLOR = RED;
	//} else {
		//COLOR = last_color;
	//}
	
	//vec3 changed = max(
		//last_color.rgb - screen_color.rgb,
		//vec3(0.0, 0.0, 0.0)
	//);
	//
	//vec4 frag = WHITE;
	//frag.rgb = abs( changed - frag.rgb );
	//COLOR = frag;
}
