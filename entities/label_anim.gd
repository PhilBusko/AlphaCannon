extends Control


func show_damage(value: int):

	$Label.text = str(value)

	const DURATION = 3.0
	const TRAVEL_DISTANCE = Vector2(0, -70)
	var tween = create_tween()

	# animate upward motion
	tween.tween_property(self, 'position', position + TRAVEL_DISTANCE, DURATION)
		#.set_trans(Tween.TRANS_QUAD)\
		#.set_ease(Tween.EASE_OUT)
	
	# animate the fade-out with modulate alpha channel
	# parallel makes next tween call simultaneous
	tween.parallel()
	tween.tween_property($Label, 'modulate', 
		Color($Label.modulate.r, $Label.modulate.g, $Label.modulate.b, 0.0), 
		DURATION *0.9)

	# use callback to free the scene instance when the tween finishes
	tween.tween_callback(queue_free)
