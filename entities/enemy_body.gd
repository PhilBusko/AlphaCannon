extends CharacterBody2D

const bullet_ref = preload('res://entities/bullet_body.tscn')
const label_ref = preload('res://entities/label_anim.tscn')
var actor_data = {}
enum shot_result {
	WRONG_DIRECTION,
	VERY_SHORT,
	MID_SHORT,
	CLOSE_SHORT,
	DIRECT_HIT,
	CLOSE_LONG,
	OFFSCREEN_LONG,
}

@onready var random = RandomNumberGenerator.new()
@onready var level_scene = get_tree().current_scene

func _ready():
	$BarrelArea.rotation_degrees = actor_data.angle_curr
	$ReloadTimer.wait_time = actor_data.reload_time
	$ReloadTimer.start()
	

#################################################################################

func _physics_process(delta: float) -> void:

	enemy_movement(delta)
	

func enemy_movement(delta):
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


func _on_reload_timeout() -> void:
	
	# recalibrate aiming based on last bullet
	
	if actor_data.orientation == 'left':
		match actor_data.last_bullet_result:
			shot_result.WRONG_DIRECTION:
				actor_data.power_curr = 1100
				actor_data.angle_curr = 45
			shot_result.VERY_SHORT:
				actor_data.power_curr += 120
				actor_data.angle_curr += 10
			shot_result.MID_SHORT:
				actor_data.power_curr += 90
				actor_data.angle_curr += 1
			shot_result.CLOSE_SHORT:
				actor_data.power_curr += 30
				actor_data.angle_curr -= 1
			shot_result.DIRECT_HIT:
				actor_data.power_curr += 0
				actor_data.angle_curr += 0
			shot_result.CLOSE_LONG:
				actor_data.power_curr -= 40
				actor_data.angle_curr += 2
			shot_result.OFFSCREEN_LONG:
				actor_data.power_curr -= 120
				actor_data.angle_curr -= 0
	
	prints('----------------------------------------------')
	prints('enemy shot', actor_data.shots_taken, actor_data.power_curr, int(actor_data.angle_curr))

	$BarrelArea.global_rotation_degrees = actor_data.angle_curr
	await get_tree().physics_frame
	await get_tree().physics_frame

	# create and shoot bullet 
	var new_bullet = bullet_ref.instantiate()
	level_scene.add_child(new_bullet)
	new_bullet.global_position = $BarrelArea/MuzzleMarker.global_position
	var barrel_dir = Vector2.LEFT.rotated($BarrelArea.global_rotation)
	var perc_range = actor_data.power_range
	var random_power = random.randi_range(
		actor_data.power_curr *(1-perc_range), 
		actor_data.power_curr *(1+perc_range)
	)
	new_bullet.apply_central_impulse(barrel_dir * random_power)

	# attach signals
	new_bullet.shooter_data = {
		'actor': 'enemy',
		'bomb_radius': actor_data.bomb_radius,
		'bomb_damage': actor_data.bomb_damage,
	}
	new_bullet.collided.connect(level_scene._on_bullet_collided)
	new_bullet.enemy_source = self
	actor_data.shots_taken += 1

	# start reloading the next
	$ReloadTimer.start()

################################################################################

func _on_damaged(damage):
	
	# TODO take damage onto enemy
	
	
	# display damage animation
	# TODO move label to position based on enemy parts
	var new_label = label_ref.instantiate()
	level_scene.add_child(new_label)
	new_label.global_position = Vector2(
		self.global_position.x,
		self.global_position.y - 40,
	)
	new_label.show_damage(damage)
	
	#self.

func bullet_landed(end_point, body):
	# called from bullet collision, where body is available
	# called from bullet leaving screen, where body is null

	prints('bullet_landed', end_point, body)

	if actor_data.orientation == 'left':
		
		var full_distance = self.global_position.x - actor_data.target_player.global_position.x
		var twothird_x = int(full_distance * 0.67) + actor_data.target_player.global_position.x
		var onethird_x = int(full_distance * 0.33) + actor_data.target_player.global_position.x
		prints('thirds', twothird_x, onethird_x)

		if end_point.x > self.global_position.x:
			actor_data.last_bullet_result = shot_result.WRONG_DIRECTION
			
		elif end_point.x > twothird_x:
			actor_data.last_bullet_result = shot_result.VERY_SHORT

		elif end_point.x > onethird_x:
			actor_data.last_bullet_result = shot_result.MID_SHORT

		elif (end_point.x <= onethird_x and 
			end_point.x >= actor_data.target_player.global_position.x and
			body != actor_data.target_player):
			actor_data.last_bullet_result = shot_result.CLOSE_SHORT

		elif body == actor_data.target_player:
			actor_data.last_bullet_result = shot_result.DIRECT_HIT

		elif end_point.x < actor_data.target_player.global_position.x and end_point.x >= 0:
			actor_data.last_bullet_result = shot_result.CLOSE_LONG

		elif end_point.x < 0:
			actor_data.last_bullet_result = shot_result.OFFSCREEN_LONG
			
		prints('shot result', actor_data.last_bullet_result)

	else:
		actor_data.last_bullet_result = 'right orientation not implemented'
