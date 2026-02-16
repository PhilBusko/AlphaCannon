'''
PLAYER BODY
'''
extends CharacterBody2D

const bullet_ref = preload('res://entities/bullet_body.tscn')
const label_ref = preload('res://entities_ui/damage_label.tscn')
const bullet_texture = preload('res://entities/sprites/bullet-white.png')
var bullets_shot = 0

@onready var level_scene = get_tree().current_scene

################################################################################

var is_moving = false 	# communicate from signal handler to physics-process
var move_start_pos: Vector2 = Vector2.ZERO
const MOVE_SPEED = 130

var is_knockback = false 	# communicate from signal handler to physics-process
var knockback_start_pos: Vector2 = Vector2.ZERO
var knockback_dist = 0
const KNOCKBACK_SPEED = 300

func _physics_process(delta):

	player_movement(delta)
	
	# this has to be handled by input.is_action_pressed 
	# because shortcut doesn't handle holding the button down
	player_aiming()
	
	# the shortcut is handling this now
	#if Input.is_action_just_pressed('shoot'):
		#shoot_bullet()

func stop_move():
	'''subroutine for player_movement'''
	velocity.x = move_toward(velocity.x, 0, MOVE_SPEED)
	is_moving = false
	move_start_pos = Vector2.ZERO

func stop_knockback():
	velocity.x = move_toward(velocity.x, 0, KNOCKBACK_SPEED)
	is_knockback = false
	knockback_start_pos = Vector2.ZERO

func player_movement(delta):
	
	# gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# user movement
	if is_moving:

		if global_position.distance_to(move_start_pos) > GlobalStats.player.move_limit:
			#print('stop move')
			stop_move()

		elif velocity.is_zero_approx():
			#print('stuck')
			stop_move()

		elif ((global_position.x <= 30 and velocity.x < 0) or 
			(global_position.x >= Utility.world_width - 30 and velocity.x > 0)):
			#print('clamped')
			stop_move()

		#else:
			#print('regular move')

	# knockback
	if is_knockback:
		
		if global_position.distance_to(knockback_start_pos) >= knockback_dist:
			#print('stop knockback')
			stop_knockback()
			
		elif velocity.is_zero_approx():
			#print('stuck')
			stop_knockback()

		elif ((global_position.x <= 30 and velocity.x < 0) or 
			(global_position.x >= Utility.world_width - 30 and velocity.x > 0)):
			#print('clamped')
			stop_knockback()

		#else:
			#print('regular knockback')

	# move after data updates
	move_and_slide()

	# stop player from moving outside world boundaries
	# doesn't work against gravity
	global_position.x = clamp(global_position.x, 30, Utility.world_width - 30)

func player_aiming():

	# change cannon angle
	var radians = 0.02
	if Input.is_action_pressed('ui_left'):
		$PlayerBarrel.rotate(-radians)
	if Input.is_action_pressed('ui_right'):
		$PlayerBarrel.rotate(radians)

	# change cannon power
	if Input.is_action_pressed('ui_up'):
		GlobalStats.player.power_curr += 10
		if GlobalStats.player.power_curr > GlobalStats.player.power_max: 
			GlobalStats.player.power_curr = GlobalStats.player.power_max
	if Input.is_action_pressed('ui_down'):
		GlobalStats.player.power_curr -= 10
		if GlobalStats.player.power_curr < GlobalStats.player.power_min: 
			GlobalStats.player.power_curr = GlobalStats.player.power_min

################################################################################

func _on_ui_pressed(ui_type):
	#prints('player_body _on_ui_pressed', ui_type)
	
	# these are "press buttons" so their code is united here
	
	if ui_type == 'shoot':
		shoot_bullet()
	if ui_type == 'move_right':
		move_player('right')
	if ui_type == 'move_left':
		move_player('left')

	# these are "down/up buttons" so they need to be implemented for each input

	var radians = 0.02
	if ui_type == 'angle_up':
		$PlayerBarrel.rotate(-radians)
	if ui_type == 'angle_down':
		$PlayerBarrel.rotate(radians)

	if ui_type == 'power_up':
		GlobalStats.player.power_curr += 10
		if GlobalStats.player.power_curr > GlobalStats.player.power_max: 
			GlobalStats.player.power_curr = GlobalStats.player.power_max
	if ui_type == 'power_down':
		GlobalStats.player.power_curr -= 10
		if GlobalStats.player.power_curr < GlobalStats.player.power_min: 
			GlobalStats.player.power_curr = GlobalStats.player.power_min

func shoot_bullet():
 
	bullets_shot += 1
	var new_bullet = bullet_ref.instantiate()
	new_bullet.name = 'BulletPlayer' + str(bullets_shot).pad_zeros(3)
	new_bullet.get_child(0).texture = bullet_texture
	new_bullet.get_child(0).scale = Vector2(0.3, 0.3)
	new_bullet.get_child(0).modulate = Color8(100, 0, 0)
	new_bullet.global_rotation = $PlayerBarrel.rotation
	level_scene.add_child(new_bullet)
	new_bullet.global_position = $PlayerBarrel/Marker2D.global_position
	
	var barrel_dir = Vector2.RIGHT.rotated($PlayerBarrel.rotation)
	var perc_range = 0.0 #GlobalStats.player.power_range
	var random_power = Utility.RNG.randi_range(
		GlobalStats.player.power_curr *(1-perc_range), 
		GlobalStats.player.power_curr *(1+perc_range)
	)
	new_bullet.apply_central_impulse(barrel_dir * random_power)
	
	new_bullet.shooter_data = {
		'actor': 'player',
		'bomb_radius': GlobalStats.player.bomb_radius,
		'bomb_damage': GlobalStats.player.bomb_damage,
	}
	new_bullet.collided.connect(level_scene._on_bullet_collided)

func move_player(side):
	
	var direction: Vector2 = Vector2.ZERO
	if side == 'right': direction = Vector2.RIGHT
	if side == 'left': direction = Vector2.LEFT

	is_moving = true
	move_start_pos = global_position
	velocity.x = direction.x * MOVE_SPEED

################################################################################

var player_enabled = true

func _process(_delta):
	
	$GravityAim.clear_points()

	if player_enabled:
		draw_aim_line()

func draw_aim_line():

	# get aim line based on max player length

	var current_pos: Vector2 = $PlayerBarrel/Marker2D.global_position
	var current_vel: Vector2 = (Vector2.RIGHT.rotated($PlayerBarrel.global_rotation) * 
		GlobalStats.player.power_curr)
	var predict_points = Utility.get_path_max_length(current_pos, current_vel, 
		GlobalStats.player.aim_max_length)

	# add the power indicator arrows

	if predict_points.size() >= 10:
		
		var ratio = (float(GlobalStats.player.power_curr - GlobalStats.player.power_min) /
			float(GlobalStats.player.power_max - GlobalStats.player.power_min))
		var draw_idx = int(predict_points.size() * ratio)
		if draw_idx == 0:
			draw_idx = 1
		if draw_idx == predict_points.size():
			draw_idx = predict_points.size() -1
		
		var point_a = predict_points[draw_idx]
		var point_b = predict_points[draw_idx -1]
		
		var direction_vector: Vector2 = point_b - point_a
		var left_arrow: Vector2 = direction_vector.rotated(deg_to_rad(45)).normalized()
		var right_arrow: Vector2 = direction_vector.rotated(deg_to_rad(135)).normalized()
		
		var min_arrow = 10
		var max_arrow = 30
		var arrow_len = (max_arrow - min_arrow) * ratio + min_arrow
		
		var new_point1 = point_a + left_arrow * arrow_len
		var new_point2 = point_a - right_arrow * arrow_len
		
		predict_points.insert(draw_idx, new_point1)
		predict_points.insert(draw_idx, point_a)
		predict_points.insert(draw_idx, new_point2)
		predict_points.insert(draw_idx, point_a)

	# display the aim line

	$GravityAim.clear_points()
	for pnt in predict_points:
		$GravityAim.add_point(to_local(pnt))

	# draw straight barrel line
	#var line_length = 500
	#var start_point = $PlayerBarrel/Marker2D.global_position
	#var end_point = start_point + Vector2.RIGHT.rotated($PlayerBarrel.global_rotation) * line_length
	#$StraightAim.clear_points()
	#$StraightAim.add_point(to_local(start_point))
	#$StraightAim.add_point(to_local(end_point))

################################################################################

func _on_damaged(_damage, collision_point):
	
	# knockback moves the player
	
	var direction = Vector2.ZERO
	if global_position.x < 100: 
		direction = Vector2.RIGHT
	elif global_position.x > Utility.world_width -100: 
		direction = Vector2.LEFT
	else: 
		if collision_point.x < global_position.x:
			direction = Vector2.RIGHT
		else:
			direction = Vector2.LEFT
	direction.y = -1

	is_knockback = true
	knockback_start_pos = global_position
	velocity = direction * KNOCKBACK_SPEED
	knockback_dist = Utility.RNG.randi_range(80, 140)

func _on_player_enabled(enabled_status):
	player_enabled = enabled_status
