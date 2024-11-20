// This shader: Optic flow applied to every pixel
shader_type canvas_item;

global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
//uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform float resScale = 2.0;
uniform float winSize = 5.0;

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0);
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}


void fragment() {
	// Pixel size (statically set to match default resolution scale of 2)
	vec2 ps = 1.0 / vec2(textureSize(TEXTURE, 0));

	// Color ranges for visualizing flow angle
	float th1 = 2.0 * PI / 3.0;
	float th2 = 4.0 * PI / 3.0;
	float th3 = 2.0 * PI;
	float thSize = 2.0 * PI / 3.0;

	// Window sum variables
	float winX = 0.0;
	float winY = 0.0;
	float winXY = 0.0;
	float winIxT = 0.0;
	float winIyT = 0.0;

	float start_x = clamp(SCREEN_UV.x - ps.x * winSize, 0.0, 1.0);
	float start_y = clamp(SCREEN_UV.y - ps.y * winSize, 0.0, 1.0);

	// Loop approach 1: use floats directly as the iteration variables
	//float end_x = clamp(SCREEN_UV.x + ps.x * winSize, 0.0, 1.0);
	//float end_y = clamp(SCREEN_UV.y + ps.y * winSize, 0.0, 1.0);
	//for (float x=start_x; x < end_x; x=x+ps.x) {
		//for (float y=start_y; y < end_y; y=y+ps.y) {

	// Loop approach 2: use ints for iteration, multiply by pixel size and add start each iteration
	for (int ix=0; ix < int(winSize * 2.0); ix++) {
		for (int iy=0; iy < int(winSize * 2.0); iy++) {
			float x = start_x + float(ix) * ps.x;
			float y = start_y + float(iy) * ps.y;

			// Intensity value of the grayscale pixel at (x,y) in current and previous stage textures
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

	float det = winX*winY - winXY*winXY;
	if (det < 0.01 && det > -0.01) {
		// det near 0
		COLOR = BLACK;
	} else {
		float trace = winX + winY;

		float uX = (-winY*winIxT + winXY*winIyT) / det;
		float uY = (winXY*winIxT - winX*winIyT) / det;

		float mag = sqrt(uX*uX + uY*uY);
		float angle = atan(uY, uX) + PI;

		float uB = mag * angle / (2.0*PI);
		float uG = mag * (2.0*PI - angle) / (2.0*PI);

		// Show uX
		//COLOR = vec4(uX, uX, uX, 1.0);

		// Show uY
		//COLOR = vec4(uY, uY, uY, 1.0);

		// Show mag
		//COLOR = vec4(mag, mag, mag, 1.0);

		// Show u
		COLOR = vec4(0.0, uB, uG, 1.0);
	}
}