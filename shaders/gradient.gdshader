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
		float x = SCREEN_UV.x;
		float y = SCREEN_UV.y;
		
		// Intensity value of the grayscale pixel at (x,y) in current and previous stage textures
		float grayIm2 = g(last_stage, x, y);
		float grayIm = g(second_last_stage, x, y);
		
		// Gradient values
		float gradImX = (g(last_stage, x+1.0, y) + g(last_stage, x-1.0, y)) / 2.0;
		float gradImY = (g(last_stage, x, y+1.0) + g(last_stage, x, y-1.0)) / 2.0;
		
		float matIx = gradImX * gradImX;
		float matIxy = gradImX * gradImY;
		float matIy = gradImY * gradImY;
		float matIt = grayIm2 - grayIm;
		float matIxIt = gradImX * matIt;
		float matIyIt = gradImY * matIt;
		
		float tg = g(last_stage, UV.x + 1.0, y);
		
		COLOR = vec4(tg, tg, tg, 1.0);
		
		// Color ranges for visualizing flow angle
		float th1 = 2.0 * PI / 3.0;
		float th2 = 4.0 * PI / 3.0;
		float th3 = 2.0 * PI;
		float thSize = 2.0 * PI / 3.0;
		
		// Window size
		int wS = 10;
		int wS1 = wS + 1;
		
		float maxMag = -1.0;
		
	//}

	//if (stage_color != BLACK && last_stage_color == BLACK) {
		//COLOR = stage_color;
	//} else {
		//COLOR = BLACK;
	//}
}