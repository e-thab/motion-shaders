shader_type canvas_item;

global uniform sampler2D last_stage;
global uniform sampler2D second_last_stage;
//global uniform sampler2D last_render;
//global uniform sampler2D vignette;
//uniform sampler2D screen_texture: hint_screen_texture, filter_nearest;

//uniform vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 winSize = vec2(1152.0, 648.0);

float g(sampler2D tex, float x, float y) {
	// Return grayscale intensity value of texture at pixel (x,y)
	vec4 col = textureLod(tex, vec2(x, y), 0.0).rgba;
	return col.r * 0.3 + col.g * 0.59 + col.b * 0.11;
}


void fragment() {
	//if (SCREEN_UV.x > 0.0 && SCREEN_UV.y > 0.0 && SCREEN_UV.x < winSize.x && SCREEN_UV.y < winSize.y) {
		// Accessing neighbor pixels needs tinkering
		// https://forum.godotengine.org/t/how-to-check-color-of-adjacent-pixels-in-fragment-shader/27296/2
		
		// Pixel size
		vec2 ps = 2.0 / vec2(textureSize(TEXTURE, 0));
		
		//float x = SCREEN_UV.x;
		//float y = SCREEN_UV.y;
		
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
		
		// Window size
		float wS = 10.0;
		float wS1 = wS + 1.0;
		
		float maxMag = -1.0;
		for (float x=SCREEN_UV.x - ps.x * wS; x < SCREEN_UV.x + ps.x * wS; x=x+ps.x) {
			for (float y=SCREEN_UV.y - ps.y * wS; y < SCREEN_UV.y + ps.y * wS; y=y+ps.y) {
				// Intensity value of the grayscale pixel at (x,y) in current and previous stage textures
				float grayIm2 = g(last_stage, x, y);
				float grayIm = g(second_last_stage, x, y);
				
				// Gradient values
				float gradImX = (g(last_stage, x+ps.x, y) + g(last_stage, x-ps.x, y)) / 2.0;
				float gradImY = (g(last_stage, x, y+ps.y) + g(last_stage, x, y-ps.y)) / 2.0;
				
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
		if (det < 0.0001 && det > -0.0001) {
			// det = 0
			COLOR = vec4(0.0, 0.0, 0.0, 0.0);
		} else {
			float trace = winX + winY;
			
			float uX = (-winY*winIxT + winXY*winIyT)/det;
			float uY = (winXY*winIxT - winX*winIyT)/det;
			
			float mag = sqrt(uX*uX + uY*uY);
			//maxMag?
			//uMag?
			float angle = atan(uY, uX) + PI;
			
			float b = mag * angle / (2.0*PI);
			float g = mag * (2.0*PI - angle) / (2.0*PI);
			COLOR = vec4(0.0, b, g, 1.0);
		}
	//}

	//if (stage_color != BLACK && last_stage_color == BLACK) {
		//COLOR = stage_color;
	//} else {
		//COLOR = BLACK;
	//}
}