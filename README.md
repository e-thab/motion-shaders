Display refresh rates beyond 60hz may cause minor flickering in optic flow shaders.

## Input Map
| Key      | Action                        |
| :------: | :---------------------------- |
| WASD     | Movement                      |
| Space    | Jump                          |
| Ctrl / C | Crouch                        |
| Shift    | Sprint                        |
| T        | Toggle shader overlay         |
| F        | Toggle shader menu            |
| +        | Increase resolution scale     |
| -        | Decrease resolution scale     |
| F7       | Toggle debug menu             |
| F2       | Get debug screenshots         |
| G        | Toggle occlusion (deprecated) |

## Viewport Overview
In total, three viewports are used to render each frame.

* The **stage** viewport: Renders the character's view. No shaders or effects are applied. The camera attached to the viewport has its location updated to match the character's head automatically by a RemoteTransform3D child of the character. The `current_frame` global shader paramater is updated to match the stage viewport texture each frame. This viewport can only be seen directly by pressing T to disable the shader overlay. Otherwise it's always rendered in the background. StageViewport should have its Update Mode property set to "Always" to allow for this behavior.

* The **render** viewport: Renders the stage view with a shader overlay on top. All that's actually "visible" through this viewport are two Sprite2Ds. The OverlayFull sprite is the same size as the screen, and applies the current shader to the stage view by using the `current_frame` parameter to read what was rendered by the stage viewport. The BG sprite displays a noise texture for a single frame to 'seed' shaders that use noise (noise is never actually generated at runtime, it will always start with the same static image for that noise type).

* The **root** viewport: The final render layer provided by default. This layer is used to render UI elements on top of the other viewports.

## Shader Overview
Each shader has a corresponding shader file and material file. The shader file, with the extension .gshader, contains the shader code itself. The material file, with the extension .tres, is what's used at runtime to apply a shader to a texture. The default shader parameters must be changed through the material files, rather than in the gshader code.

**Stage pixels** are the pixels from the stage viewport. These are the pixels from the image you would see when disabling the shader overlay.

**Render pixels** are the pixels from the render viewport. These are the pixels you see when the shader overlay is enabled.

Three sampler2D uniforms are declared at the top of each gshader file.

```
global uniform sampler2D current_frame;
global uniform sampler2D last_frame;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
```

**current_frame** is the texture of the stage viewport rendered *this* frame. Displaying this texture every frame would be the same as displaying the stage viewport. In the main.gd _ready() function, the stage viewport's *viewport texture* is assigned to this parameter, which is a special texture that tells Godot to update the parameter's texture each frame automatically while assigned.

**last_frame** is the texture of the stage viewport rendered *last* frame. Motion is determined by finding the color differences between this texture and current_frame. After each frame is drawn, an instance of the current stage viewport texture is captured and assigned manually in the main.gd post_draw() function. There's currently no built-in way to do this automatically, which is frustrating as it leaves the shaders functionally CPU-bound. Rather than relying strictly on GPU computations, each frame must wait for post_draw() in main.gd to finish processing on the CPU. For now it doesn't appear to cause performance issues, but finding a way around it would be nice.

**screen_texture** is the texture of the entire game window, captured as the shader is processed. This texture is used to read what was rendered last frame, allowing shaders to *not change* a render pixel's color by just setting it to the same color as last frame. It's very important that the render viewport's clear mode is set to "Next Frame" so that data isn't cleared at the beginning of each frame to allow for this behavior. UI elements aren't captured because they're rendered by the root viewport, which is drawn last.

## Shader Types

### Invert
**Appearance:** Moving pixels are inverted from last frame.

**Algorithm:** Compares each stage pixel with the stage pixel from the previous frame at the same location. If the difference is higher than the diff Threshold parameter, invert the color of the render pixel from the previous render frame.

* **Shader** `shaders/invert.gshader`
* **Material** `materials/shader_invert.tres`

### Binary
**Appearance:** Moving pixels are swapped between two specified colors.

**Algorithm:** Compares each stage pixel with the stage pixel from the previous frame at the same location. If the difference is higher than the diff Threshold parameter, swap render color between Color 1 and Color 2 parameters.
* **Shader** `shaders/binary.gshader`
* **Material** `materials/shader_binary.tres`

### Increment
**Appearance:** Moving pixels are nudged toward pure black or pure white back and forth (rather than cycling). White pixels in motion are darkened slightly until they reach black, black pixels in motion are lightened slightly until they reach white.

**Algorithm:** If the difference between current and last stage pixel is greater than the diff threshold param, nudge render pixel color a small amount toward black or white. The direction they're nudged flips whenever they reach pure black or white. An imperceptible difference in the red channel is used to keep track of the current direction.
* **Shader** `shaders/increment.gshader`
* **Material** `materials/shader_increment.tres`

### Fade
**Appearance:** Moving pixels are illuminated with a specified color, stationary pixels are darkened toward (or stay) black.

**Algorithm:** If the difference between current and last stage pixel is greater than the diff threshold param, set render pixel color to the fade color param. If nothing changes, nudge pixels toward black according to the fade speed param.
* **Shader** `shaders/fade.gshader`
* **Material** `materials/shader_fade.tres`

### Fade (full color)
**Appearance:** Moving pixels are illuminated with their respective stage color, stationary pixels are darkened toward (or stay) black. The more motion is present the closer this shader appears to the original scene/stage viewport.

**Algorithm:** If the difference between current and last stage pixel is greater than the diff threshold param, set render pixel color to the stage pixel color. If nothing changes, nudge pixels toward black according to the fade speed param.
* **Shader** `shaders/fade_fullcolor.gshader`
* **Material** `materials/shader_fade_fullcolor.tres`

### Optic Flow (constrained)
**Appearance:** Optic flow is applied to moving pixels. Blue pixels are moving horizontally, while green are moving vertically, with blending so that cyan are moving diagonally. There are sharp lines at the edge of moving areas.

**Algorithm:** If the difference between current and last stage pixel is greater than the diff threshold param, iterate over pixels in a small neighborhood (Win Size) of pixels around current. Set render color to indicate the direction the pixel is most likely moving in.
* **Shader** `shaders/optic_flow.gshader`
* **Material** `materials/shader_optic_flow.tres`

### Optic Flow (every pixel)
**Appearance:** Optic flow is applied to every pixel so that motion detection arises from optic flow calculations themselves and not by applying a difference threshold as with the other shaders. Blue pixels are moving horizontally, while green are moving vertically, with blending. The edges of moving areas are less well defined, showing the size of the neighborhoods used in the optic flow calculations. Regions without movement may show some 'stuck' pixels that aren't in motion, but whose determinant calculations are outside the threshold.

**Algorithm:** Iterate over pixels in a small neighborhood (Win Size) of pixels around current. Set render color to indicate the direction the pixel is most likely moving in. Applied to every pixel rather than according to diff threshold.
* **Shader** `shaders/optic_flow_all.gshader`
* **Material** `materials/shader_optic_flow_all.tres`


## Noise

The shaders affected by noise are Invert and Increment. Changing noise type while using these will greatly change how they look, though Binary will display previously rendered noise if it was on screen just before switching. Changing noise type while using either Fade or either Optic Flow shader should have no affect. The noise types are:

* **Binary:** Each pixel is randomly assigned color values of either black or white.
  
* **Linear:** Each pixel is randomly assigned a value in the range from black to white.
  
* **Full Color:** Each pixel is randomly assigned any possible opaque color value.
  
* **Perlin:** Gray scale gradient noise that appears smoother and more natural.
  
* **Fill Black:** Solid black fill.
  
* **Fill White:** Solid white fill.
  