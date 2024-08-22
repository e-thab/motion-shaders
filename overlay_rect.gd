extends TextureRect

var prev_frame_texture

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prev_frame_texture = ImageTexture.new()
	
	var width = get_viewport_rect().size.x
	var height = get_viewport_rect().size.y
	print(width, "x", height)
	
	var noise_img = Image.create(width, height, false, Image.FORMAT_RGB8)
	
	#noise_img.fill(Color.RED)
	randomize()
	
	for x in range(width):
		for y in range(height):
			if randi() % 2 == 0:
				noise_img.set_pixel(x, y, Color.WHITE)
			else:
				noise_img.set_pixel(x, y, Color.BLACK)
	
	prev_frame_texture = ImageTexture.create_from_image(noise_img)
	texture = prev_frame_texture
	
	print("Pixel (300, 300): ", noise_img.get_pixel(300, 300))
	print("Overlay texture size: ", texture.get_size())
	#print("Control size: ", size)
	#set_texture(prev_frame_texture)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
