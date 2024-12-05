// This shader: Optic flow applied only to pixels changing outside a given threshold
shader_type canvas_item;
global uniform sampler2D current_frame;
global uniform sampler2D last_frame;

uniform float res_scale = 1.0;
uniform float win_size = 5.0;
uniform float diff_threshold = 0.15;

const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0);
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}

void fragment() {
	//vec4 stage_color = textureLod(current_frame, SCREEN_UV, 0.0).rgba;
	//vec4 last_stage_color = textureLod(last_frame, SCREEN_UV, 0.0).rgba;
	//if (abs(stage_color.r - last_stage_color.r) > diffThreshold ||
		//abs(stage_color.g - last_stage_color.g) > diffThreshold ||
		//abs(stage_color.b - last_stage_color.b) > diffThreshold) {

	float current_g = g(current_frame, SCREEN_UV.x, SCREEN_UV.y);
	float last_g = g(last_frame, SCREEN_UV.x, SCREEN_UV.y);

	if (abs(current_g - last_g) < diff_threshold) {
		COLOR = BLACK;
	} else {
		// Pixel size based on resolution scale
		vec2 ps = res_scale / vec2(textureSize(TEXTURE, 0));

		// Color ranges for visualizing flow angle
		//float th1 = 2.0 * PI / 3.0;
		//float th2 = 4.0 * PI / 3.0;
		//float th3 = 2.0 * PI;
		//float thSize = 2.0 * PI / 3.0;

		// Window sum variables
		float winX = 0.0;
		float winY = 0.0;
		float winXY = 0.0;
		float winIxT = 0.0;
		float winIyT = 0.0;

		float start_x = clamp(SCREEN_UV.x - ps.x * win_size, 0.0, 1.0);
		//float end_x = clamp(SCREEN_UV.x + ps.x * win_size, 0.0, 1.0);
		float start_y = clamp(SCREEN_UV.y - ps.y * win_size, 0.0, 1.0);
		//float end_y = clamp(SCREEN_UV.y + ps.y * win_size, 0.0, 1.0);

		//for (float x=SCREEN_UV.x - ps.x * win_size; x < SCREEN_UV.x + ps.x * win_size; x=x+ps.x) {
			//for (float y=SCREEN_UV.y - ps.y * win_size; y < SCREEN_UV.y + ps.y * win_size; y=y+ps.y) {
		//for (float x=start_x; x < end_x; x=x+ps.x) {
			//for (float y=start_y; y < end_y; y=y+ps.y) {

		// Loop approach 2: use ints for iteration, multiply by pixel size and add start each iteration
		for (int ix=0; ix < int(win_size * 2.0); ix++) {
			for (int iy=0; iy < int(win_size * 2.0); iy++) {
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
		if (det == 0.0) {
			// det near 0
			COLOR = BLACK;
		} else {
			float trace = winX + winY;

			float uX = (-winY*winIxT + winXY*winIyT)/det;
			float uY = (winXY*winIxT - winX*winIyT)/det;

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
	//else {
		//COLOR = BLACK;
	//}
}