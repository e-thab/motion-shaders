shader_type canvas_item;

global uniform sampler2D last_stage;
global uniform sampler2D second_last_stage;
global uniform sampler2D last_render;
global uniform sampler2D vignette;
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
	vec4 render_color = textureLod(last_render, SCREEN_UV, 0.0).rgba;
	float v = textureLod(screen_texture, SCREEN_UV, 0.0).a;

	if (stage_color == WHITE && last_stage_color == BLACK) {
		if (render_color == COLOR_1) {
			COLOR = COLOR_2;
			//COLOR = vec4(COLOR_2.r, COLOR_2.g, COLOR_2.b, screen_color.a);
			//COLOR.r = stage_color.r + (render_color.r - stage_color.r) * v;
			//COLOR.g = stage_color.g + (render_color.g - stage_color.g) * v;
			//COLOR.b = stage_color.b + (render_color.b - stage_color.b) * v;
		} else {
			COLOR = COLOR_1;
			//COLOR = vec4(COLOR_1.r, COLOR_1.g, COLOR_1.b, screen_color.a);
		}
	} else {
		COLOR = render_color;
		//COLOR = vec4(render_color.r, render_color.g, render_color.b, screen_color.a);
	}
}