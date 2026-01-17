extends Node2D


func _ready() -> void:

	#print(Engine.get_frames_per_second())


	# position player dynamically
	const player_cannon = preload("res://entities/player/player_body.tscn")
	var new_player = player_cannon.instantiate()
	get_tree().current_scene.add_child(new_player)
	new_player.global_position = Vector2(50, 300)
	new_player.get_node('BarrelArea').rotation_degrees = -45
	

var has_collision = null

func _on_collided(collision_point, body):
	#print('screen collided ', collision_point)
	has_collision = collision_point
	queue_redraw()

func _draw():
	# draw with graphics to debug
	# available on node2d and canvasitem, draws on layer 0
	#draw_grid()
	
	if has_collision:
		draw_circle(has_collision, GlobalStats.player.bomb_radius, Color(255,255,255), false)
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
