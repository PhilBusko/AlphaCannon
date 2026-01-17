extends Node

var player = {
	'power_min': 500,
	'power_max': 1300,
	'power_curr': 700,
	'power_range': 0.2,

	'bomb_damage': 20,
	'bomb_radius': 50,
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
	'power_curr': 700,
	'angle_curr': -45,

	'power_range': 0.3,
	'bomb_damage': 20,
	'bomb_radius': 30,

	'reload_time': 4.0,
	'health': 100,
	'wounds': 0,
	'color_mask': null,
}

var materials ={
	'plant': 1,
	'soil': 5,
	'stone': 10,
}
