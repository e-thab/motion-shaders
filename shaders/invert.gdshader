// This shader: invert previous frame color on motion
shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

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

void fragment() {
	vec4 render_color = textureLod(screen_texture, SCREEN_UV, 0.0);
	float current_g = g(current_frame, SCREEN_UV.x, SCREEN_UV.y);
	float last_g = g(last_frame, SCREEN_UV.x, SCREEN_UV.y);
	
	if (abs(current_g - last_g) >= diff_threshold) {
		// On motion: invert
		COLOR = vec4(
			1.0 - render_color.r,
			1.0 - render_color.g,
			1.0 - render_color.b,
			1.0
		);
	} else {
		// Otherwise: no change
		COLOR = render_color;
	}
}