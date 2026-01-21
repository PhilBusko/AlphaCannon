extends Node2D

@onready var random = RandomNumberGenerator.new()
@onready var world_width = get_viewport_rect().size[0]
@onready var world_height = get_viewport_rect().size[1]

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
	new_player.global_position = Vector2(
		random.randi_range(50, world_width *1/4),
		300,
	)
	new_player.get_node('BarrelArea').rotation_degrees = -45
	self.player_damaged.connect(new_player._on_damaged)

	# spawn enemy
	var new_enemy = enemy_ref.instantiate()
	new_enemy.actor_data = GlobalStats.enemy_level1
	add_child(new_enemy)
	new_enemy.global_position = Vector2(
		random.randi_range(world_width *3/4, world_width -50), 
		300,
	)
	self.enemy_damaged.connect(new_enemy._on_damaged)

################################################################################

signal player_damaged
signal enemy_damaged

var mountain_index = 0
var has_collision = null
var collision_radius = null

func _on_bullet_collided(collision_point, collision_body, shooter):

	# explode any soil and entities
	$DetectionArea.global_position = collision_point
	$DetectionArea/CollisionShape2D.shape.radius = shooter.bomb_radius

	# must advance physics frame for detection	
	await get_tree().physics_frame
	await get_tree().physics_frame

	var bodies_in_range = $DetectionArea.get_overlapping_bodies()
	#print('------------------------------------------------------')
	#prints(collision_point, collision_body.name)
	#print(bodies_in_range)

	var has_underground = bodies_in_range.filter(func(bd): return 'Underground' in bd.name)
	has_underground = true if has_underground.size() > 0 else false
	
	for bd in bodies_in_range:

		if 'Enemy' in bd.name and bd == collision_body:
			enemy_damaged.emit(shooter.bomb_damage)
			
		elif 'Enemy' in bd.name:
			enemy_damaged.emit(int(shooter.bomb_damage /2))
			
		if bd.name == 'PlayerBody' and bd == collision_body:
			player_damaged.emit(shooter.bomb_damage)
			
		elif bd.name == 'PlayerBody':
			player_damaged.emit(int(shooter.bomb_damage /2))

		if 'Mountain' in bd.name:
			
			#if (has_collision and 
				#has_collision == collision_point and
				#curr_bd == collision_body and
				#not has_underground
			#):
				#print('collision error')

			handle_mountain(collision_point, shooter, bd)
	
	# mark the screen for debug
	has_collision = collision_point
	collision_radius = shooter.bomb_radius
	queue_redraw()


func handle_mountain(collision_point, shooter, curr_bd):

	#prints('starting', curr_bd.name, curr_bd.get_child(1).polygon.size())

	# subtract the area exploded by bomb
	# a polygon must have at least 3 and unique points to be valid

	var ground_poly = curr_bd.get_child(0).polygon
	var bomb_poly = generate_circle_polygon(shooter.bomb_radius, collision_point, 18)
	var intersect_poly = Geometry2D.intersect_polygons(ground_poly, bomb_poly)

	if ground_poly.size() <= 3:
		curr_bd.queue_free()
		return

	if len(intersect_poly) == 0:
		#print('no inters')
		intersect_poly = intersect_poly
	elif len(intersect_poly) == 1:
		#print('single inters ', len(intersect_poly))
		intersect_poly = intersect_poly[0]
	elif len(intersect_poly) > 1:
		#print('inters multi ', len(intersect_poly))
		if len(intersect_poly[0]) > len(intersect_poly[1]):
			intersect_poly = intersect_poly[0]
		else:
			intersect_poly = intersect_poly[1]

	#print('inters ', len(intersect_poly))
	intersect_poly = remove_duplicates(intersect_poly)
	#print('inters dedup ', len(intersect_poly))

	# debug drawing
	has_intersect = intersect_poly
	queue_redraw()

	var x_poly = []
	if len(intersect_poly) > 3:
		x_poly = Geometry2D.exclude_polygons(ground_poly, intersect_poly)
		#print('x-poly parts ', len(x_poly))
	
		if len(x_poly) == 0:
			#print('delete ', curr_bd.name)
			curr_bd.queue_free()
	
		elif len(x_poly) == 1:
			x_poly = remove_duplicates(x_poly[0])
			x_poly = remove_stragglers(x_poly, collision_point, shooter.bomb_radius)
			#prints('single assign', curr_bd.name, len(x_poly))
			curr_bd.get_child(0).set_deferred('polygon', x_poly)
			curr_bd.get_child(1).set_deferred('polygon', x_poly)

		elif len(x_poly) > 1:
			
			var main_assigned = 0
			for xprt in x_poly:
				
				var curr_poly = remove_duplicates(xprt)
				curr_poly = remove_stragglers(curr_poly, collision_point, shooter.bomb_radius)

				# there is a bug sometimes where the subtracted area is also returned
				if len(curr_poly) <= 3 or len(curr_poly) == len(intersect_poly):
					#prints('skipping len', len(curr_poly))
					continue
				
				if main_assigned == 0:
					#prints('multi assign', curr_bd.name, curr_poly.size())
					curr_bd.get_child(0).set_deferred('polygon', curr_poly)
					curr_bd.get_child(1).set_deferred('polygon', curr_poly)
					main_assigned += 1
				
				else:
					var new_copy = curr_bd.duplicate()
					mountain_index += 1
					new_copy.name = 'Mountain' + str(mountain_index).pad_zeros(2)
					#prints('creating', new_copy.name, curr_poly.size())
					new_copy.get_child(0).set_deferred('polygon', curr_poly)
					new_copy.get_child(1).set_deferred('polygon', curr_poly)
					$TerrainNode.add_child(new_copy)

func generate_circle_polygon(radius, center, segments):
	var points = []
	for i in range(segments):
		var angle = float(i) / segments * 2.0 * PI
		var x = radius * sin(angle) + center.x
		var y = radius * cos(angle) + center.y
		points.append(Vector2(x, y))
	return points

func remove_duplicates(points: Array) -> Array:
	var unique_pnts = []
	for check_pt in points:
		var found = false
		for existing_pt in unique_pnts:
			if check_pt.distance_to(existing_pt) < 2:
				found = true
				#prints('doop found', check_pt, existing_pt)
				break
		if not found:
			unique_pnts.append(check_pt)
	return unique_pnts

func remove_stragglers(check_poly, collision_point, radius):
	var non_stragglers = []
	var check_radius = radius -1
	for cpt in check_poly:
		var is_straggler = false
		if cpt.distance_to(collision_point) < check_radius:
			is_straggler = true
			prints('straggler found', cpt, collision_point)
		if not is_straggler:
			non_stragglers.append(cpt)
	return non_stragglers


################################################################################

var has_intersect = []

func _draw():
	# draw with graphics to debug
	# available on node2d and canvasitem, draws on layer 0
	#draw_grid()
	#draw_thirds()
	
	#var points := PackedVector2Array()
	#points.append(Vector2(100, 100))
	#points.append(Vector2(200, 100))
	#points.append(Vector2(200, 200))
	#points.append(Vector2(100, 200))
	#draw_polygon(points, [Color(1,1,1)])
	
	
	if len(has_intersect) >= 3:
		draw_polygon(has_intersect, [Color(0,0,0, 0.2)])
	
	if has_collision:
		draw_circle(has_collision, collision_radius, Color(0,0,0), false)
		draw_circle(has_collision, 2, Color(0,0,0), true)
	
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

func draw_thirds():

	# draw grid for debugging
	var GRID_X = get_viewport_rect().size[0] / 3
	var GRID_Y = get_viewport_rect().size[1] / 3
	const COLOR = Color(255, 255, 255) 
	var top_left = Vector2.ZERO
	var bottom_right = Vector2(get_viewport_rect().size[0], get_viewport_rect().size[1])

	# Draw vertical lines
	for i in range(int(top_left.x / GRID_X) - 1, int(bottom_right.x / GRID_X) + 2):
		var x_pos = i * GRID_X
		draw_line(Vector2(x_pos, top_left.y), Vector2(x_pos, bottom_right.y), COLOR)

	# Draw horizontal lines
	for i in range(int(top_left.y / GRID_Y) - 1, int(bottom_right.y / GRID_Y) + 2):
		var y_pos = i * GRID_Y
		draw_line(Vector2(top_left.x, y_pos), Vector2(bottom_right.x, y_pos), COLOR)
