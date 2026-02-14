'''
DAMAGE LABEL
'''
extends Control

func show_damage(value, collision_point):

	self.text = str(value)
	var start_pos = Vector2(collision_point.x -15, collision_point.y -50)
	print(start_pos)
	self.global_position = start_pos
	self.modulate = Color(modulate.r, modulate.g, modulate.b, 1.0)

	const DURATION = 2.8
	const TRAVEL_DISTANCE = Vector2(0, -60)
	var tween = create_tween()

	# animate upward motion
	tween.tween_property(self, 'position', position + TRAVEL_DISTANCE, DURATION)
		#.set_trans(Tween.TRANS_QUAD)\
		#.set_ease(Tween.EASE_OUT)

	# animate the fade-out with modulate alpha channel
	# parallel makes next tween call simultaneous
	tween.parallel()
	tween.tween_property(self, 'modulate', 
		Color(modulate.r, modulate.g, modulate.b, 0.0), 
		DURATION)
