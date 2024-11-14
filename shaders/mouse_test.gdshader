shader_type canvas_item;

global uniform vec2 mouse_pos;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform vec2 c = vec2(576.0, 324.0);

void fragment() {
    //if (SCREEN_UV.x == 0.1) {
		//COLOR = vec4(0.0, 1.0, 0.0, 1.0);
	//}
	if (length(SCREEN_UV - mouse_pos) < 0.01) {
		COLOR = vec4(0.0, 1.0, 0.0, 1.0);
	} 
	else {
		COLOR = textureLod(screen_texture, SCREEN_UV, 0.0);
	}
}