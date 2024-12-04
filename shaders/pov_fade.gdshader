shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 fade_color: source_color;
uniform float fade_speed = 0.06;
uniform float diff_threshold = 0.25;

const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0);
	vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0);

	//if (stage_color != BLACK && last_stage_color == BLACK) {
		//COLOR = FADE_COLOR;
	//} else {
		//COLOR = BLACK;
	//}

	if (abs(stage_color.r - last_stage_color.r) > diff_threshold ||
		abs(stage_color.g - last_stage_color.g) > diff_threshold ||
		abs(stage_color.b - last_stage_color.b) > diff_threshold) {
		COLOR = fade_color;
	} else {
		vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);
		COLOR = vec4(
			render_color.r - fade_speed,
			render_color.g - fade_speed,
			render_color.b - fade_speed,
			1.0
		);
	}
}