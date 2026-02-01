extends Node

var player = {
	'power_min': 500,
	'power_max': 1300,
	'power_curr': 700,
	'power_range': 0.2,

	'bomb_damage': 20,
	'bomb_radius': 30,
	'aim_points': 30,
	'move_limit': 0,

	'reload_time': 3.0,
	'health': 100,
	'wounds': 0,

	'character_level': 1,
	'badges': 0,
	'advances': [],
	'campaign_level': 1,
}

var player_level1 = {
	
}

var enemy_ls = []

var enemy_level1 = {
	'power_curr': 1050,		# calibration from enemy halfway spawn to player halfway spawn for 1800x900 screen 
	'angle_curr': 60,		# power 1200, angle 60
	'orientation': null,
	'target_player': null,
	'shots_taken': 1,

	'power_range': 0.1,
	'bomb_damage': 20,
	'bomb_radius': 30,
	'reload_time': 4.0,

	'enemy_id': null,
	'health': 100,
	'wounds': 0,
	'color_mask': null,
}
