extends StaticBody2D

var rng = RandomNumberGenerator.new()
@onready var world_width = get_viewport_rect().size[0]
@onready var world_height = get_viewport_rect().size[1]


func _ready() -> void:
	
	generate_mountain()
	
	generate_indestructible()
	
	generate_stone()
	
	# add trees and plants
	

func generate_mountain():
	
	var points := PackedVector2Array()
	points.append(Vector2(0, world_height * 5/6))
	points.append(Vector2(world_width * 4/10, world_height * 5/6))
	points.append(Vector2(world_width * 4/10, world_height * 2/6))
	points.append(Vector2(world_width * 6/10, world_height * 2/6))
	points.append(Vector2(world_width * 6/10, world_height * 3/6))
	points.append(Vector2(world_width * 10/10, world_height * 3/6))
	
	points.append(Vector2(world_width, world_height))
	points.append(Vector2(0, world_height))
	
	$SoilFill.polygon = points
	$SoilCollision.polygon = points

func generate_indestructible():
	
	var bottom_mask := PackedVector2Array()
	var half_hill = 50
	var num_hills = int(world_width / half_hill) +1

	for hl in num_hills:
		if hl % 2 == 0:
			bottom_mask.append(Vector2(-half_hill + hl*half_hill, world_height -50))
			bottom_mask.append(Vector2(hl*half_hill, world_height -65))
		else:
			bottom_mask.append(Vector2(-half_hill + hl*half_hill, world_height -65))
			bottom_mask.append(Vector2(hl*half_hill, world_height -50))

	bottom_mask.append(Vector2(world_width +50, world_height +50))
	bottom_mask.append(Vector2(-50, world_height +50))
	$BottomFill.polygon = bottom_mask
	$BottomCollision.polygon = bottom_mask

func generate_stone():
	
	# TODO the number of stone sections is a function of the campaign level
	var num_stones = rng.randi_range(1, 3) + 4 #GlobalStats.player.campaign_level
	var center_ls = []
	
	for stn in num_stones:
		
		var new_body = StaticBody2D.new()
		new_body.name = 'Stone' + str(stn).pad_zeros(2)
		add_child(new_body)
		
		var results = create_stone(center_ls)
		var stone_poly = results[0]
		center_ls.append(results[1])
		
		var new_fill = Polygon2D.new()
		new_fill.polygon = stone_poly
		new_fill.color = Color8(90, 90, 120)
		new_body.add_child(new_fill)
		
		var new_collision = CollisionPolygon2D.new()
		new_collision.polygon = stone_poly
		new_body.add_child(new_collision)

func create_stone(center_ls):
	
	# stone center inside the soil model
	var center = Vector2(
		 rng.randi_range(world_width *0.1, world_width *0.9), 
		 rng.randi_range(world_height *0.3, world_height *0.9), 
	)
	while not Geometry2D.is_point_in_polygon(center, $SoilFill.polygon):
		center = Vector2(
			rng.randi_range(world_width *0.1, world_width *0.9), 
			rng.randi_range(world_height *0.3, world_height *0.9), 
		)

	# polygon to set stone shape
	var stone_unit = 80.0
	var points := PackedVector2Array()
	points.append(Vector2(
		center.x - rng.randi_range(stone_unit/4, stone_unit), 
		center.y - rng.randi_range(stone_unit/4, stone_unit), 
	))
	points.append(Vector2(
		center.x + rng.randi_range(stone_unit/4, stone_unit), 
		center.y - rng.randi_range(stone_unit/4, stone_unit), 
	))
	points.append(Vector2(
		center.x + rng.randi_range(stone_unit/4, stone_unit), 
		center.y + rng.randi_range(stone_unit/4, stone_unit), 
	))
	points.append(Vector2(
		center.x - rng.randi_range(stone_unit/2, stone_unit), 
		center.y + rng.randi_range(stone_unit/2, stone_unit), 
	))
	
	return [points, center]



func _on_collided(collision_point, body):

	$DetectionArea.global_position = collision_point
	$DetectionArea/CollisionShape2D.shape.radius = GlobalStats.player.bomb_radius

	# must advance physics frame for detection
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var bodies_in_range = $DetectionArea.get_overlapping_bodies()	
	for bd in bodies_in_range:
		if bd == self: 
			
			# subtract the area exploded by bomb
			# the bottom mask is used to mitigate the ground being split into multiple polygons
			# a polygon must have at least 3 and unique points to be valid
			
			var ground_poly = bd.get_child(0).polygon
			var bomb_poly = generate_circle_polygon(GlobalStats.player.bomb_radius, collision_point, 18)
			var mask_poly = self.get_child(2).polygon
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
