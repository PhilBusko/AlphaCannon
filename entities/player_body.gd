extends CharacterBody2D

const bullet_ref = preload('res://entities/bullet_body.tscn')
const label_ref = preload('res://entities/label_anim.tscn')

var rng = RandomNumberGenerator.new()
@onready var level_scene = get_tree().current_scene

const SPEED = 300.0

################################################################################

func _physics_process(delta):

	player_movement(delta)
	
	player_aiming()
	
	shoot_bullet()

func player_movement(delta):
	
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# player movement input
	var direction := Input.get_axis('move_left', 'move_right')
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# stop player from moving outside world boundaries
	# doesn't work against gravity
	var screen_size = get_viewport_rect().size
	var half_player_width = 25
	global_position.x = clamp(global_position.x, half_player_width, screen_size.x - half_player_width)

	# move after data updates
	move_and_slide()

func player_aiming():

	# change cannon angle
	var radians = 0.02
	if Input.is_action_pressed('angle_left'):
		$BarrelArea.rotate(-radians)
	if Input.is_action_pressed('angle_right'):
		$BarrelArea.rotate(radians)

	# change cannon power
	if Input.is_action_pressed('power_up'):
		GlobalStats.player.power_curr += 10
		if GlobalStats.player.power_curr > GlobalStats.player.power_max: 
			GlobalStats.player.power_curr = GlobalStats.player.power_max
	if Input.is_action_pressed('power_down'):
		GlobalStats.player.power_curr -= 10
		if GlobalStats.player.power_curr < GlobalStats.player.power_min: 
			GlobalStats.player.power_curr = GlobalStats.player.power_min

func shoot_bullet():

	if Input.is_action_just_pressed('shoot'):
		var new_bullet = bullet_ref.instantiate()
		level_scene.add_child(new_bullet)
		
		new_bullet.global_position = $BarrelArea/Marker2D.global_position
		var barrel_dir = Vector2.RIGHT.rotated($BarrelArea.rotation)
		var perc_range = 0.0 #GlobalStats.player.power_range
		var random_power = rng.randi_range(
			GlobalStats.player.power_curr *(1-perc_range), 
			GlobalStats.player.power_curr *(1+perc_range)
		)
		new_bullet.apply_central_impulse(barrel_dir * random_power)
		new_bullet.set_meta('shooter', {
			'actor': 'player',
			'bomb_radius': GlobalStats.player.bomb_radius,
			'bomb_damage': GlobalStats.player.bomb_damage,
		})

		new_bullet.collided.connect(level_scene._on_bullet_collided)

func _process(delta):

	# draw straight barrel line
	# must map to the local position of the line

	var line_length = 500
	var start_point = $BarrelArea/Marker2D.global_position #+ Vector2.RIGHT * 100
	var end_point = start_point + Vector2.RIGHT.rotated($BarrelArea.global_rotation) * line_length
	$StraightAim.clear_points()
	$StraightAim.add_point(to_local(start_point))
	$StraightAim.add_point(to_local(end_point))

	# draw gravity based trajectory

	var num_points = 80
	var current_pos: Vector2 = $BarrelArea/Marker2D.global_position
	var current_vel: Vector2 = Vector2.RIGHT.rotated($BarrelArea.global_rotation) * GlobalStats.player.power_curr
	var predict_points = predict_path(current_pos, current_vel, num_points, delta)

	$GravityAim.clear_points()
	for pnt in predict_points:
		$GravityAim.add_point(to_local(pnt))

	#current_pos = $BarrelArea/Marker2D.global_position
	#current_vel = Vector2.RIGHT.rotated($BarrelArea.global_rotation) * cannon_power * 0.9
	#predict_points = predict_path(current_pos, current_vel, num_points, delta)
#
	#$GravityAim2.clear_points()
	#for pnt in predict_points:
		#$GravityAim2.add_point(to_local(pnt))
#
	#current_pos = $BarrelArea/Marker2D.global_position
	#current_vel = Vector2.RIGHT.rotated($BarrelArea.global_rotation) * cannon_power * 1.1
	#predict_points = predict_path(current_pos, current_vel, num_points, delta)
#
	#$GravityAim3.clear_points()
	#for pnt in predict_points:
		#$GravityAim3.add_point(to_local(pnt))

func predict_path(start_pos, start_vel, steps, time_step):
	var path_points = []
	var current_pos = start_pos
	var current_vel = start_vel
	var linear_damp = 0.002
	#var space_state = get_world_2d().direct_space_state # Or PhysicsServer2D.get_space_state()

	for i in range(steps):
		
		# find the next point
		current_vel += get_gravity() * time_step
		current_vel *= (1.0 - linear_damp)
		current_pos += current_vel * time_step

		# check for collision
		var is_collide = false
		# var query = PhysicsShapeQueryParameters2D.new()
		# query.set_shape(...) // Define shape to cast
		#// query.transform = Transform2D(0, current_pos)
		#// var result = space_state.intersect_shape(query)
		#// if result.size() > 0:
		#//     // Hit something! Add hit point and break or get reflection
		#//     path_points.append(result[0].position)
		#//     break
		
		if not is_collide:
			path_points.append(current_pos)
		else:
			break

	return path_points

################################################################################

func _on_damaged(damage):
	
	# TODO take damage onto player
	
	
	# display damage animation
	var new_label = label_ref.instantiate()
	level_scene.add_child(new_label)
	new_label.global_position = Vector2(
		self.global_position.x,
		$BarrelArea/Marker2D.global_position.y - 20
	)
	new_label.show_damage(damage)
