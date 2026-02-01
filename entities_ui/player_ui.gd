extends Node2D

var current_health = GlobalStats.player.health

@onready var damage_label : Label = $WrapperVBox/HighHBox/DamageLabel


func _ready():
	damage_label.modulate = Color(
		damage_label.modulate.r, damage_label.modulate.g, damage_label.modulate.b, 0.0)


#func _process(_delta):
	#if not $ShootButton/ShootTimer.is_stopped():
		## Update progress bar: (1 - timeleft / total_time)
		#$ShootButton/ShootProgressBar.value = (1.0 - 
			#($ShootButton/ShootTimer.time_left / $ShootButton/ShootTimer.wait_time)) * 100
	#else:
		#$ShootButton/ShootProgressBar.value = 100


func _on_ability_pressed():
	if $ShootButton/ShootTimer.is_stopped():
		$ShootButton/ShootTimer.start()
		# Start UI animation


func _on_damaged(damage, collision_point):
	current_health -= damage
	damage_label.show_damage(damage, collision_point)
