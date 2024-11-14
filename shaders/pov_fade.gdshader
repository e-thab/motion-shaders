shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
//global uniform sampler2D last_render;
//global uniform sampler2D vignette;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 FADE_COLOR = vec4(0.0, 1.0, 0.5, 1.0);
uniform float FADE_AMOUNT = 0.06;
uniform float DIFF_THRESHOLD = 0.25;

void fragment() {
	vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0).rgba;
	vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0).rgba;

	if (stage_color != BLACK && last_stage_color == BLACK) {
		COLOR = FADE_COLOR;
	} else {
		COLOR = BLACK;
	}

	//if (abs(stage_color.r - last_stage_color.r) > DIFF_THRESHOLD ||
		//abs(stage_color.g - last_stage_color.g) > DIFF_THRESHOLD ||
		//abs(stage_color.b - last_stage_color.b) > DIFF_THRESHOLD) {
		//COLOR = FADE_COLOR;
	//} else {
		//vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0).rgba;
//
		//COLOR = vec4(
			//render_color.r - FADE_AMOUNT,
			//render_color.g - FADE_AMOUNT,
			//render_color.b - FADE_AMOUNT,
			//1.0
		//);
	//}
}