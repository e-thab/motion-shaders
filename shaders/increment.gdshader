// This shader: gradually increment colors toward black/white on motion.
// Colors seesaw between black and white, gradually moving toward full black,
// then full white, then back to black and so on.
shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

// The difference in intensity required to consider a pixel to have 'changed'
// from the previous frame, indicating the presence of motion.
// 1.0 means only detecting 100% intensity difference
// 0.0 means detecting any difference
uniform float diff_threshold = 0.15;

// The amount the color is nudged each frame
// 1.0 means full inversion (identical to the behavior of invert.gshader)
// 0.0 means no change (static screen)
uniform float inc = 0.15;

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
		// On motion: check screen pixel color
		if (render_color.g == 1.0) {
			// If the green channel is 1, time to start decreasing.
			// Decrease by inc value and set an imperceptibly lower red channel
			// value to signify decreasing for the next frame.
			COLOR.rgb = vec3(1.0-inc-0.01, 1.0-inc, 1.0-inc);
		} else if (render_color.r < render_color.g) {
			// If the red channel is less than the green, we must be decreasing.
			// Decrease color value by inc value.
			COLOR.rgb = vec3(
				render_color.r - inc,
				render_color.g - inc,
				render_color.b - inc
			);
		} else {
			// Otherwise, we're increasing. Increase by inc value
			COLOR.rgb = vec3(
				render_color.r + inc,
				render_color.g + inc,
				render_color.b + inc
			);
		}
	} else {
		// No motion: no change
		COLOR = render_color;
	}
}