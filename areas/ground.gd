extends StaticBody2D

var rng = RandomNumberGenerator.new()
@onready var world_width = get_viewport_rect().size[0]
@onready var world_height = get_viewport_rect().size[1]
@onready var stone_ref = preload("res://areas/stone.tscn")
var stone_unit = 50.0

func _ready() -> void:
	
	generate_mountain()

	generate_indestructible()

	generate_stone()
	
	# add trees and plants
	

func generate_mountain():
	
	var points := PackedVector2Array()
	points.append(Vector2(0, world_height * 4/6))
	points.append(Vector2(world_width * 4/10, world_height * 4/6))
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
	var num_stones = rng.randi_range(1, 3) + 10 #GlobalStats.player.campaign_level
	var center_ls = []
		
	for stn in num_stones:
		
		var results = create_points(center_ls)
		var stone_poly = results[0]
		var center = results[1]
		center_ls.append(center)
		
		var new_stone = stone_ref.instantiate()
		new_stone.name = 'Stone' + str(stn).pad_zeros(2)
		new_stone.get_child(0).polygon = stone_poly
		new_stone.get_child(1).polygon = stone_poly
		new_stone.get_child(2).global_position = center
		add_child(new_stone)

func create_points(center_ls):

	# stone center inside the soil model
	var center = Vector2()
	while true:
		center = Vector2(
			 rng.randi_range(world_width *0.1, world_width *0.9), 
			 rng.randi_range(world_height *0.3, world_height *0.9), 
		)
		var is_in_soil = Geometry2D.is_point_in_polygon(center, $SoilFill.polygon)
		var is_distant = is_far_from_centers(center, center_ls)
		if is_in_soil and is_distant:
			break
	
	# polygon to set stone shape
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

func is_far_from_centers(center, center_ls):
	for ct in center_ls:
		if center.distance_to(ct) < float(stone_unit):
			return false
	return true

################################################################################
