shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

//uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);


void fragment() {
	vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0);
	vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0);
	vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);

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