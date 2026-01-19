extends CharacterBody2D

const bullet_ref = preload('res://entities/bullet_body.tscn')
const label_ref = preload('res://entities/label_anim.tscn')
var actor_data = {}

@onready var random = RandomNumberGenerator.new()
@onready var level_scene = get_tree().current_scene


func _ready():
	print(actor_data)
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
	
	# shoot bullet 
	
	var new_bullet = bullet_ref.instantiate()
	level_scene.add_child(new_bullet)
	new_bullet.global_position = $BarrelArea/MuzzleMarker.global_position
	var barrel_dir = Vector2.LEFT.rotated($BarrelArea.global_rotation)
	var perc_range = 0 #actor_data.power_range
	var random_power = random.randi_range(
		actor_data.power_curr *(1-perc_range), 
		actor_data.power_curr *(1+perc_range)
	)
	new_bullet.apply_central_impulse(barrel_dir * random_power)
	new_bullet.set_meta('shooter', {
		'actor': 'enemy',
		'bomb_radius': actor_data.bomb_radius,
		'bomb_damage': actor_data.bomb_damage,
	})

	new_bullet.collided.connect(level_scene._on_bullet_collided)
	
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
