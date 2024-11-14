extends Control

func _draw() -> void:
	var MousePos: Vector2 = get_local_mouse_position() # <-- `draw_x` methods expect local coordinates

	draw_rect(Rect2(MousePos,Vector2(10,10)),Color(1,1,0,.05),true)
	draw_rect(Rect2(MousePos+Vector2(0,10),Vector2(10,10)),Color(1,1,1,.1),true)
	draw_rect(Rect2(MousePos+Vector2(0,20),Vector2(10,10)),Color(0,1,0,.2),true)

func _process(_delta: float) -> void:
	visible = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if visible:
		queue_redraw()
