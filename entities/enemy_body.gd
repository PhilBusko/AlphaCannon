'''
ENEMY BODY
'''
extends CharacterBody2D

const bullet_ref = preload('res://entities/bullet_body.tscn')
const label_ref = preload('res://entities_ui/damage_label.tscn')
var actor_data = {}

@onready var level_scene = get_tree().current_scene

func _ready():
	$BarrelArea.rotation_degrees = actor_data.angle_curr
	$ReloadTimer.wait_time = actor_data.reload_time
	$ReloadTimer.start()

################################################################################

var is_knockback = false 	# communicate from signal handler to physics-process
var knockback_start_pos: Vector2 = Vector2.ZERO
var knockback_dist = 0
const KNOCKBACK_SPEED = 300

func _physics_process(delta: float) -> void:

	enemy_movement(delta)

func stop_knockback():
	velocity.x = move_toward(velocity.x, 0, KNOCKBACK_SPEED)
	is_knockback = false
	knockback_start_pos = Vector2.ZERO

func enemy_movement(delta):
	
	if not is_on_floor():
		velocity += get_gravity() * delta

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

	move_and_slide()

################################################################################

func _on_reload_timeout() -> void:
	
	prints('----------------------------------------------')
	prints('enemy shot', actor_data.shots_taken)
	
	# get the path

	$AimLineNeg.clear_points()
	$AimLinePos.clear_points()

	var results = await get_hit_path()
	var power_range = 0
	var random_power = Utility.RNG.randi_range(
		results.power_hit - power_range, 
		results.power_hit + power_range, 
	)
	actor_data.power_curr = random_power
	actor_data.angle_curr = results.angle_hit

	$BarrelArea/AimMarker.global_rotation_degrees = results.angle_hit
	var start_pos = $BarrelArea/AimMarker.global_position
	var start_vel = (Vector2.LEFT.rotated($BarrelArea/AimMarker.global_rotation) * 
		(results.power_hit - power_range))
	var points = Utility.get_path_collision(start_pos, start_vel)
	for pnt in points: $AimLineNeg.add_point(to_local(pnt))

	$BarrelArea/AimMarker.global_rotation_degrees = results.angle_hit
	start_pos = $BarrelArea/AimMarker.global_position
	start_vel = (Vector2.LEFT.rotated($BarrelArea/AimMarker.global_rotation) * 
		(results.power_hit + power_range))
	points = Utility.get_path_collision(start_pos, start_vel)
	for pnt in points: $AimLinePos.add_point(to_local(pnt))

	# shoot on chosen path
	create_and_shoot()

	# reload next bullet
	$ReloadTimer.start()

func get_hit_path():

	var power_hit = actor_data.power_curr
	var angle_hit = actor_data.angle_curr
	var points = []

	for trial in 12:
		
		$BarrelArea/AimMarker.global_rotation_degrees = angle_hit
		var start_pos = $BarrelArea/AimMarker.global_position
		var start_vel = Vector2.LEFT.rotated($BarrelArea/AimMarker.global_rotation) * power_hit

		points = Utility.get_path_collision(start_pos, start_vel)
		var last_point = points[-1]

		$AimLine.clear_points()
		for pnt in points: $AimLine.add_point(to_local(pnt))
		for itr in 10: await get_tree().physics_frame

		if last_point.distance_to(actor_data.target_player.global_position) <= 40:
			break
		else:
			
			if actor_data.orientation == 'left':
				if last_point.x > self.global_position.x:
					power_hit = GlobalStats.enemy_level1.power_curr
					angle_hit = GlobalStats.enemy_level1.angle_curr
				elif last_point.x > self.global_position.x -300:
					power_hit += 30
					angle_hit += 5
				elif last_point.x > actor_data.target_player.global_position.x +140:
					power_hit += 20
					angle_hit += 0
				# close but short
				elif last_point.x > actor_data.target_player.global_position.x:
					power_hit += 5
					angle_hit -= 1
				# close but long
				elif last_point.x > actor_data.target_player.global_position.x -140:
					power_hit -= 3
					angle_hit += 1
				elif (last_point.x < actor_data.target_player.global_position.x and
					last_point.x > 0):
					power_hit -= 15
					angle_hit += 0
				else:
					power_hit -= 40
					angle_hit -= 2

				if power_hit > 1600: power_hit = 1500
				if angle_hit > 75: angle_hit = 60
				if angle_hit < 40: angle_hit = 60

			else:
				print('rightward targeting not implemented')
	
	return {
		'power_hit': power_hit,
		'angle_hit': angle_hit,
	}

func create_and_shoot():
	
	# TODO use tween to move barrel
	$BarrelArea.global_rotation_degrees = actor_data.angle_curr

	# create 
	var new_bullet = bullet_ref.instantiate()
	new_bullet.name = 'BulletEnemy' + str(actor_data.shots_taken).pad_zeros(3)
	#new_bullet.get_child(0).texture = bullet_texture
	#new_bullet.get_child(0).scale = Vector2(0.3, 0.3)
	#new_bullet.get_child(0).modulate = Color8(100, 0, 0)
	level_scene.add_child(new_bullet)
	
	# shoot
	new_bullet.global_position = $BarrelArea/MuzzleMarker.global_position
	var barrel_dir = Vector2.LEFT.rotated($BarrelArea.global_rotation)
	new_bullet.apply_central_impulse(barrel_dir * actor_data.power_curr)
	
	# attach signals
	new_bullet.shooter_data = {
		'actor': 'enemy',
		'bomb_radius': actor_data.bomb_radius,
		'bomb_damage': actor_data.bomb_damage,
	}
	new_bullet.collided.connect(level_scene._on_bullet_collided)
	actor_data.shots_taken += 1

################################################################################

func _on_damaged(_damage, collision_point):
	#prints('enemy damaged', damage, collision_point)
	
	# knockback

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


	# take damage onto enemy
	
	# display damage animation
	#var new_label = label_ref.instantiate()
	#level_scene.add_child(new_label)
	#new_label.global_position = Vector2(
		#self.global_position.x,
		#self.global_position.y - 40,
	#)
	#new_label.show_damage(damage)
