extends RigidBody2D

var shooter_data = {}

@onready var world_width = get_viewport_rect().size[0]
@onready var world_height = get_viewport_rect().size[1]

################################################################################

# ground and screen subscribe to this
signal collided

# one shot call on collision
func _on_body_entered(body):
	
	# get the collision point based on current body
	var state = PhysicsServer2D.body_get_direct_state(get_rid())
	var collision_point = state.get_contact_local_position(0)

	# correct the position if the body has a polygon as first child
	var collision_corrected = collision_point
	if 'polygon' in body.get_child(0):
		var closest_point = get_closest_point_on_polygon(collision_point, body.get_child(0).polygon)
		collision_corrected = (collision_point + closest_point) / 2.0
	#print(collision_point)
	#print(collision_corrected)

	collided.emit(collision_corrected, body, shooter_data)

	# delete this bullet
	queue_free()

func get_closest_point_on_polygon(point_to_check: Vector2, polygon_points: PackedVector2Array) -> Vector2:
	var closest_point: Vector2 = Vector2.INF
	var min_distance_sq: float = INF
	var points_count: int = polygon_points.size()

	if points_count < 2:
		return closest_point # Or handle error/edge case

	for i in range(points_count):
		# Get the start and end points of the current segment
		var p1: Vector2 = polygon_points[i]
		# The last point connects back to the first one to close the polygon
		var p2: Vector2 = polygon_points[(i + 1) % points_count]

		# Use Godot's built-in method to find the closest point on the segment
		var current_closest_on_segment: Vector2 = Geometry2D.get_closest_point_to_segment(point_to_check, p1, p2)

		# Calculate the distance squared (more efficient than distance_to() for comparison)
		var current_distance_sq: float = point_to_check.distance_squared_to(current_closest_on_segment)

		# Check if this segment's closest point is closer than the current overall closest
		if current_distance_sq < min_distance_sq:
			min_distance_sq = current_distance_sq
			closest_point = current_closest_on_segment

	return closest_point

################################################################################

func _physics_process(_delta: float) -> void:
	
	self.global_rotation = self.linear_velocity.angle()
	
	# no need for VisibleOnScreenNotifier2D
	if position.x < 0 or position.x > world_width:
		queue_free()
