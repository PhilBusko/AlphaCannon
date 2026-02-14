'''
UTILITY
'''
extends Node2D

@onready var world_width = get_viewport_rect().size[0]
@onready var world_height = get_viewport_rect().size[1]

@onready var RNG = RandomNumberGenerator.new()

var gravity_vc = Vector2(0, ProjectSettings.get_setting('physics/2d/default_gravity'))
func get_path_collision(start_pos, start_vel, steps):
	'returns all points on the path based on the parameters'
	
	# delta should be very small so max length doesn't jitter
	var delta = 1.0 / Engine.physics_ticks_per_second /5
	var space_state = get_viewport().find_world_2d().direct_space_state
	var linear_damp = 0.0015

	var path_points = [start_pos]
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

func get_path_max_length(start_pos, start_vel, max_length):

	var full_points = get_path_collision(start_pos, start_vel, 500)
	var curr_point_idx = 0
	var curr_point = full_points[curr_point_idx]
	var max_points = []

	while start_pos.distance_to(curr_point) <= max_length:
		max_points.append(curr_point)
		if curr_point_idx != full_points.size() -1:
			curr_point_idx += 1
			curr_point = full_points[curr_point_idx]
		else:
			break

	return max_points
