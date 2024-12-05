shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

uniform float inc = 0.15;
uniform float diff_threshold = 0.15;

const vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
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
		if (render_color.g == 1.0) {
			// Imperceptibly lower r signifies decreasing
			COLOR.rgb = vec3(1.0-inc-0.01, 1.0-inc, 1.0-inc);
		} else if (render_color.r < render_color.g) {
			// Decreasing
			COLOR.rgb = vec3(
				render_color.r - inc,
				render_color.g - inc,
				render_color.b - inc
			);
		} else {
			// Increasing
			COLOR.rgb = vec3(
				render_color.r + inc,
				render_color.g + inc,
				render_color.b + inc
			);
		}
	} else {
		COLOR = render_color;
	}
}