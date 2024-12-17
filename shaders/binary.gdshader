// This shader: toggle between two specified colors on motion
shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

// Colors to toggle between
// Defaults are set by the material (materials/shader_binary.tres)
uniform vec4 color_1: source_color;
uniform vec4 color_2: source_color;

// The difference in intensity required to consider a pixel to have 'changed'
// from the previous frame, indicating the presence of motion.
// 1.0 means only detecting 100% intensity difference
// 0.0 means detecting any difference
uniform float diff_threshold = 0.15;

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0);
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}

bool colorMatch(vec4 c1, vec4 c2) {
	// Return if color c1 is (roughly) equivalent to color c2
	float maxDiff = 0.001;
	return (
		abs(c1.r - c2.r) < maxDiff
		&& abs(c1.g - c2.g) < maxDiff
		&& abs(c1.b - c2.b) < maxDiff
	);
}

void fragment() {
	vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	float current_g = g(current_frame, SCREEN_UV.x, SCREEN_UV.y);
	float last_g = g(last_frame, SCREEN_UV.x, SCREEN_UV.y);

	if (abs(current_g - last_g) >= diff_threshold) {
		// On motion: swap color
		if (colorMatch(render_color, color_1)) {
			COLOR = color_2;
		} else {
			COLOR = color_1;
		}
	} else {
		// Otherwise: no change
		COLOR = render_color;
	}
}