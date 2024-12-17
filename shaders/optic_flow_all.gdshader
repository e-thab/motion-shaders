// This shader: Optic flow applied to every pixel
shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

// The resolution to use when determining pixel size with respect to screen textures.
// Each frame is passed to the shader as a texture, which can only be addressed with
// floats representing portional values. In other shaders that's very useful, but
// here we have to calculate how big a portion of the texture each pixel takes up.
uniform float res_scale = 1.0;

// The size of the neighborhood windows to search around each pixel. This is actually
// half the real size in each direction minus one. A window size of 5 really means
// checking 5 pixels out in all directions from the center, resulting in a total actual
// window size of 11x11.
uniform float win_size = 5.0;

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0);
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}

void fragment() {
	// Find pixel size based on resolution scale
	vec2 ps = res_scale / vec2(textureSize(TEXTURE, 0));

	// Window sum variables
	float winX = 0.0;
	float winY = 0.0;
	float winXY = 0.0;
	float winIxT = 0.0;
	float winIyT = 0.0;

	// Loop over neighborhood pixels. 'Pixels' here are floats representing
	// portional texture coverage. So I'm using ints for iteration, multiplying
	// by pixel size and adding the start value each iteration.
	float start_x = clamp(SCREEN_UV.x - ps.x * win_size, 0.0, 1.0);
	float start_y = clamp(SCREEN_UV.y - ps.y * win_size, 0.0, 1.0);

	for (int ix=0; ix < int(win_size * 2.0); ix++) {
		for (int iy=0; iy < int(win_size * 2.0); iy++) {
			// Calculate loop offset
			float x = start_x + float(ix) * ps.x;
			float y = start_y + float(iy) * ps.y;

			// Intensity value of the grayscale pixel at (x,y) in current and
			// previous stage textures.
			float grayIm2 = g(current_frame, x, y);
			float grayIm = g(last_frame, x, y);

			// Gradient values
			float gradImX = (g(current_frame, x+ps.x, y) + g(current_frame, x-ps.x, y)) / 2.0;
			float gradImY = (g(current_frame, x, y+ps.y) + g(current_frame, x, y-ps.y)) / 2.0;

			float matIx = gradImX * gradImX;
			float matIxy = gradImX * gradImY;
			float matIy = gradImY * gradImY;
			float matIt = grayIm2 - grayIm;
			float matIxIt = gradImX * matIt;
			float matIyIt = gradImY * matIt;

			winX += matIx;
			winY += matIy;
			winXY += matIxy;
			winIxT += matIxIt;
			winIyT += matIyIt;
		}
	}

	// Find determinant
	float det = winX*winY - winXY*winXY;
	if (abs(det) < 0.02) {
		// Determinant near zero: likely no motion.
		// Using if (abs == 0.0) like in optic_flow.gshader results in large areas
		// of static color remaining on the screen even when there's no motion. This
		// is still visible with a threshold of 0.02, but much better.
		COLOR = BLACK;
	} else {
		float trace = winX + winY;

		float uX = (-winY*winIxT + winXY*winIyT) / det;
		float uY = (winXY*winIxT - winX*winIyT) / det;

		float mag = sqrt(uX*uX + uY*uY);
		float angle = atan(uY, uX) + PI;

		float uB = mag * angle / (2.0*PI);
		float uG = mag * (2.0*PI - angle) / (2.0*PI);

		// Show u
		COLOR = vec4(0.0, uB, uG, 1.0);

		//// Visualizing component values
		// Show uX
		//COLOR = vec4(uX, uX, uX, 1.0);
		// Show uY
		//COLOR = vec4(uY, uY, uY, 1.0);
		// Show mag
		//COLOR = vec4(mag, mag, mag, 1.0);
	}
}