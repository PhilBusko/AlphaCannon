'''
PLAYER UI
'''
extends Node2D

#var current_health = GlobalStats.player.health

@onready var damage_label : Label = $WrapperVBox/HighHBox/DamageLabel
@onready var action_pbar : ProgressBar = $WrapperVBox/ReloadHBox/ActionProgressBar
@onready var action_timer : Timer = $WrapperVBox/ReloadHBox/ActionTimer
@onready var knockback_timer : Timer = $WrapperVBox/ReloadHBox/KnockbackTimer

################################################################################

func _ready():
	
	# set the damage label to off
	damage_label.modulate = Color(
		damage_label.modulate.r, damage_label.modulate.g, damage_label.modulate.b, 0.0)
		
	# initialize the action reload
	action_pbar.max_value = GlobalStats.player.reload_time
	action_timer.wait_time = GlobalStats.player.reload_time

################################################################################

var is_angle_up = false
var is_angle_down = false
var is_power_up = false
var is_power_down = false

func _process(_delta):
	
	# user holding down button
	
	if is_angle_up:
		ui_pressed.emit('angle_up')
	if is_angle_down:
		ui_pressed.emit('angle_down')
		
	if is_power_up:
		ui_pressed.emit('power_up')
	if is_power_down:
		ui_pressed.emit('power_down')

	# update the reload cooldown
	
	if action_timer.is_stopped() == false:
		action_pbar.value = action_timer.wait_time - action_timer.time_left

################################################################################

signal ui_pressed
signal player_enabled

@onready var shoot_button : TextureButton = $WrapperVBox/BottomHBox/ShootButton
@onready var right_button : TextureButton = $WrapperVBox/BottomHBox/MoveRightButton
@onready var left_button : TextureButton = $WrapperVBox/BottomHBox/MoveLeftButton

func _on_shoot_pressed():
	ui_pressed.emit('shoot')
	start_action()

func _on_move_right_pressed() -> void:
	ui_pressed.emit('move_right')
	start_action()

func _on_move_left_pressed() -> void:
	ui_pressed.emit('move_left')
	start_action()

func start_action():
	shoot_button.disabled = true
	right_button.disabled = true
	left_button.disabled = true
	action_timer.start()
	player_enabled.emit(false)

func _on_action_timer_timeout() -> void:
	if knockback_timer.is_stopped():
		shoot_button.disabled = false
		right_button.disabled = false
		left_button.disabled = false
		player_enabled.emit(true)

################################################################################

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

################################################################################

func _on_damaged(damage, collision_point):
	#current_health -= damage

	# show damage amount
	damage_label.show_damage(damage, collision_point)

	# knockback disables actions
	shoot_button.disabled = true
	right_button.disabled = true
	left_button.disabled = true
	knockback_timer.start()
	player_enabled.emit(false)

func _on_knockback_timer_timeout() -> void:
	if action_timer.is_stopped():
		shoot_button.disabled = false
		right_button.disabled = false
		left_button.disabled = false
		player_enabled.emit(true)

################################################################################
