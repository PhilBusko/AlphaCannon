extends Label

func _process(_delta):
	var mouse_pos = get_global_mouse_position()
	text = "X: " + str(mouse_pos.x) + ", Y: " + str(mouse_pos.y)
