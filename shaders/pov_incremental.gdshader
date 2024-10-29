shader_type canvas_item;

global uniform sampler2D last_stage;
global uniform sampler2D second_last_stage;
global uniform sampler2D last_render;
global uniform sampler2D vignette;
//uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform float inc = 0.15;


void fragment() {
	vec4 stage_color = textureLod(last_stage, SCREEN_UV, 0.0).rgba;
	vec4 last_stage_color = textureLod(second_last_stage, SCREEN_UV, 0.0).rgba;
	vec4 render_color = textureLod(last_render, SCREEN_UV, 0.0).rgba;
	//float v = textureLod(screen_texture, SCREEN_UV, 0.0).a;

	if (stage_color != BLACK && last_stage_color == BLACK) {
		if (render_color.g == 1.0) {
			// Imperceptibly lower r signifies decreasing
			COLOR = vec4(1.0-inc-0.01, 1.0-inc, 1.0-inc, 1.0);
		} else if (render_color.r < render_color.g) {
			// Decreasing
			COLOR = vec4(
				render_color.r - inc,
				render_color.g - inc,
				render_color.b - inc,
				1.0
			);
		} else {
			// Increasing
			COLOR = vec4(
				render_color.r + inc,
				render_color.g + inc,
				render_color.b + inc,
				1.0
			);
		}
	} else {
		COLOR = render_color;
		//COLOR = vec4(render_color.r, render_color.g, render_color.b, screen_color.a);
	}
}