extends Node


var gravity_vc = Vector2(0, ProjectSettings.get_setting('physics/2d/default_gravity'))

func get_path_collision(start_pos, start_vel, steps):
	'returns all points on the path based on the parameters'
	var linear_damp = 0.0015
	var delta = 1.0 / Engine.physics_ticks_per_second
	var space_state = get_viewport().find_world_2d().direct_space_state
	
	var path_points = []
	var current_pos = start_pos
	var current_vel = start_vel

	for i in range(steps):
		
		# find the next point
		current_vel += gravity_vc * delta
		current_vel *= (1.0 - linear_damp)
		var next_pos = current_pos + current_vel * delta

		# check for collision
		var is_collide = false
		var query = PhysicsRayQueryParameters2D.create(current_pos, next_pos)
		var result = space_state.intersect_ray(query)
		if result:
			is_collide = true 

		current_pos = next_pos
		if not is_collide:
			path_points.append(current_pos)
		else:
			path_points.append(result.position)
			break

	return path_points
