shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform float FADE_AMOUNT = 0.08;
uniform float DIFF_THRESHOLD = 0.25;

void fragment() {
	vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0);
	vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0);

	if (stage_color != BLACK && (
		abs(stage_color.r - last_stage_color.r) > DIFF_THRESHOLD ||
		abs(stage_color.g - last_stage_color.g) > DIFF_THRESHOLD ||
		abs(stage_color.b - last_stage_color.b) > DIFF_THRESHOLD)
	) {
		// As long as the stage pixel isn't black and the color diff is outside the threshold
		COLOR = stage_color;
	} else {
		vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);
		COLOR = vec4(
			render_color.r - FADE_AMOUNT,
			render_color.g - FADE_AMOUNT,
			render_color.b - FADE_AMOUNT,
			1.0
		);
	}

	//if (abs(stage_color.r - last_stage_color.r) > 0.25) {
		//COLOR.r = 1.0;
	//}
	//if (abs(stage_color.g - last_stage_color.g) > 0.25) {
		//COLOR.g = 1.0;
	//}
	//if (abs(stage_color.b - last_stage_color.b) > 0.25) {
		//COLOR.b = 1.0;
	//}
}