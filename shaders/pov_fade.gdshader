shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 fade_color: source_color;
uniform float fade_speed = 0.06;
uniform float diff_threshold = 0.15;

const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0);
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}

bool colorMatch(vec4 c1, vec4 c2) {
	float maxDiff = 0.001;
	return (
		abs(c1.r - c2.r) < maxDiff
		&& abs(c1.g - c2.g) < maxDiff
		&& abs(c1.b - c2.b) < maxDiff
	);
}

void fragment() {
	//vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0);
	//vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0);

	float current_g = g(current_frame, SCREEN_UV.x, SCREEN_UV.y);
	float last_g = g(last_frame, SCREEN_UV.x, SCREEN_UV.y);

	if (abs(current_g - last_g) >= diff_threshold) {
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