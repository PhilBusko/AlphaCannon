extends Node2D

################################################################################

const player_ref = preload('res://entities/player_body.tscn')
const enemy_ref = preload('res://entities/enemy_body.tscn')

func _ready() -> void:

	#print(Engine.get_frames_per_second())
	
	# this could trigger on signal from ground, so ground can spawn first
	# spawn player
	var new_player = player_ref.instantiate()
	#new_player.actor_data = GlobalStats.player
	add_child(new_player)
	new_player.global_position = Vector2(50, 300)
	new_player.get_node('BarrelArea').rotation_degrees = -45
	self.player_damaged.connect(new_player._on_damaged)

	# spawn enemy
	var new_enemy = enemy_ref.instantiate()
	new_enemy.actor_data = GlobalStats.enemy_level1
	add_child(new_enemy)
	new_enemy.global_position = Vector2(1050, 300)
	self.enemy_damaged.connect(new_enemy._on_damaged)
	


################################################################################

signal player_damaged
signal enemy_damaged

var has_collision = null
var collision_radius = null

func _on_bullet_collided(collision_point, collision_body, shooter):

	# mark the screen for debug
	has_collision = collision_point
	collision_radius = shooter.bomb_radius
	queue_redraw()

	# explode any ground and entities
	
	$DetectionArea.global_position = collision_point
	$DetectionArea/CollisionShape2D.shape.radius = shooter.bomb_radius

	# must advance physics frame for detection
	await get_tree().physics_frame
	await get_tree().physics_frame

	var bodies_in_range = $DetectionArea.get_overlapping_bodies()
	#print(bodies_in_range)
	
	for bd in bodies_in_range:

		if 'Enemy' in bd.name and bd == collision_body:
			enemy_damaged.emit(shooter.bomb_damage)
			
		elif 'Enemy' in bd.name:
			enemy_damaged.emit(int(shooter.bomb_damage /2))
			
		if bd.name == 'PlayerBody' and bd == collision_body:
			player_damaged.emit(shooter.bomb_damage)
			
		elif bd.name == 'PlayerBody':
			player_damaged.emit(int(shooter.bomb_damage /2))

		if bd.name == 'Ground': 
			
			# subtract the area exploded by bomb
			# the bottom mask is used to mitigate the ground being split into multiple polygons
			# a polygon must have at least 3 and unique points to be valid
			
			var ground_poly = bd.get_child(0).polygon
			var bomb_poly = generate_circle_polygon(shooter.bomb_radius, collision_point, 18)
			var mask_poly = bd.get_child(2).polygon
			var bomb_mask_poly = Geometry2D.intersect_polygons(bomb_poly, mask_poly)
			var bomb_filter_poly = bomb_poly
			if len(bomb_mask_poly) > 0:
				bomb_filter_poly = Geometry2D.exclude_polygons(bomb_poly, bomb_mask_poly[0])[0]
			var intersect_poly = Geometry2D.intersect_polygons(ground_poly, bomb_filter_poly)
			
			var x_poly = []
			if len(intersect_poly) > 0 and len(intersect_poly[0]) > 3:
				x_poly = Geometry2D.exclude_polygons(ground_poly, intersect_poly[0])
				x_poly = remove_duplicates(x_poly[0])
				bd.get_child(0).polygon = x_poly
				bd.get_child(1).polygon = x_poly

			#print('ground ', len(ground_poly))
			#print('bomb ', len(bomb_poly))
			#print('mask ', len(mask_poly))
			#print('bomb_filter ', len(bomb_filter_poly))
			#print('intersect ', len(intersect_poly[0]) if len(intersect_poly) > 0 else 0)
			#print('final ', len(x_poly))

func generate_circle_polygon(radius, center, segments):
	var points = []
	for i in range(segments):
		var angle = float(i) / segments * 2.0 * PI
		var x = radius * cos(angle) + center.x
		var y = radius * sin(angle) + center.y
		points.append(Vector2(x, y))
	return points

func remove_duplicates(points: Array) -> Array:
	var unique_dict = {}
	for p in points:
		unique_dict[p] = true
	return unique_dict.keys()

################################################################################

func _draw():
	# draw with graphics to debug
	# available on node2d and canvasitem, draws on layer 0
	#draw_grid()
	pass
	if has_collision:
		draw_circle(has_collision, collision_radius, Color(255,255,255), false)
		draw_circle(has_collision, 2, Color(255,255,255), true)
	
	#draw_circle(Vector2(500, 500), 50, Color(255,255,255), false)

func draw_grid():

	# draw grid for debugging
	const GRID_SIZE = 100
	const COLOR = Color(255, 255, 255) 
	var top_left = Vector2.ZERO
	var bottom_right = Vector2(get_viewport_rect().size[0], get_viewport_rect().size[1])

	# Draw vertical lines
	for i in range(int(top_left.x / GRID_SIZE) - 1, int(bottom_right.x / GRID_SIZE) + 2):
		var x_pos = i * GRID_SIZE
		draw_line(Vector2(x_pos, top_left.y), Vector2(x_pos, bottom_right.y), COLOR)

	# Draw horizontal lines
	for i in range(int(top_left.y / GRID_SIZE) - 1, int(bottom_right.y / GRID_SIZE) + 2):
		var y_pos = i * GRID_SIZE
		draw_line(Vector2(top_left.x, y_pos), Vector2(bottom_right.x, y_pos), COLOR)
