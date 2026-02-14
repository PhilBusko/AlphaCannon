'''
PLAYER UI
'''
extends Node2D

var current_health = GlobalStats.player.health

@onready var damage_label : Label = $WrapperVBox/HighHBox/DamageLabel
@onready var shoot_button : TextureButton = $WrapperVBox/BottomHBox/ShootButton

################################################################################

func _ready():
	damage_label.modulate = Color(
		damage_label.modulate.r, damage_label.modulate.g, damage_label.modulate.b, 0.0)

################################################################################

var is_angle_up = false
var is_angle_down = false
var is_power_up = false
var is_power_down = false

func _process(_delta):
	
	if is_angle_up:
		ui_pressed.emit('angle_up')
	if is_angle_down:
		ui_pressed.emit('angle_down')
		
	if is_power_up:
		ui_pressed.emit('power_up')
	if is_power_down:
		ui_pressed.emit('power_down')



################################################################################

func _on_damaged(damage, collision_point):
	#current_health -= damage
	damage_label.show_damage(damage, collision_point)

################################################################################

signal ui_pressed

func _on_shoot_pressed():
	ui_pressed.emit('shoot')


func _on_move_right_pressed() -> void:
	ui_pressed.emit('move_right')

func _on_move_left_pressed() -> void:
	ui_pressed.emit('move_left')


func _on_angle_up_button_down() -> void:
	is_angle_up = true
func _on_angle_up_button_up() -> void:
	is_angle_up = false

func _on_angle_down_button_down() -> void:
	is_angle_down = true
func _on_angle_down_button_up() -> void:
	is_angle_down = false

func _on_power_up_button_down() -> void:
	is_power_up = true
func _on_power_up_button_up() -> void:
	is_power_up = false

func _on_power_down_button_down() -> void:
	is_power_down = true
func _on_power_down_button_up() -> void:
	is_power_down = false
