shader_type canvas_item;

global uniform sampler2D last_stage;
global uniform sampler2D second_last_stage;
//global uniform sampler2D last_render;
uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

//uniform vec4 COLOR_1 = vec4(1.0, 1.0, 1.0, 1.0);
//uniform vec4 COLOR_2 = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 COLOR_1 = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 COLOR_2 = vec4(0.0, 0.0, 0.0, 1.0);


void fragment() {
	vec4 stage_color = textureLod(last_stage, SCREEN_UV, 0.0).rgba;
	vec4 last_stage_color = textureLod(second_last_stage, SCREEN_UV, 0.0).rgba;
	vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgba;

	if (stage_color == WHITE && last_stage_color == BLACK) {
		if (render_color == COLOR_1) {
			COLOR = COLOR_2;
		} else {
			COLOR = COLOR_1;
		}
	} else {
		COLOR = render_color;
	}
}