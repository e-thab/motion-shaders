shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform float diff_threshold = 0.15;

//uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0);
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}

void fragment() {
	//vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0);
	//vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0);
	vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	float current_g = g(current_frame, SCREEN_UV.x, SCREEN_UV.y);
	float last_g = g(last_frame, SCREEN_UV.x, SCREEN_UV.y);

	//if (stage_color != BLACK && last_stage_color == BLACK) {
	if (abs(current_g - last_g) >= diff_threshold) {
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