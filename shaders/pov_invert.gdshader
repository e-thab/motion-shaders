shader_type canvas_item;

global uniform sampler2D last_stage;
global uniform sampler2D second_last_stage;
global uniform sampler2D last_render;
global uniform sampler2D vignette;
//uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

//uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);


void fragment() {
	vec4 stage_color = textureLod(last_stage, SCREEN_UV, 0.0).rgba;
	vec4 last_stage_color = textureLod(second_last_stage, SCREEN_UV, 0.0).rgba;
	vec4 render_color = textureLod(last_render, SCREEN_UV, 0.0).rgba;

	if (stage_color != BLACK && last_stage_color == BLACK) {
		COLOR = vec4(
			1.0 - render_color.r,
			1.0 - render_color.g,
			1.0 - render_color.b,
			1.0
		);
	} else {
		COLOR = render_color;
	}
}