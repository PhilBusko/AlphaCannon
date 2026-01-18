extends CharacterBody2D

const bullet_ref = preload('res://entities/bullet_body.tscn')
const label_ref = preload('res://entities/label_anim.tscn')

var rng = RandomNumberGenerator.new()
@onready var level_scene = get_tree().current_scene

#################################################################################

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

################################################################################

func _on_damaged(damage):
	
	# TODO take damage onto enemy
	
	
	# display damage animation
	# TODO move label to position based on enemy parts
	var new_label = label_ref.instantiate()
	level_scene.add_child(new_label)
	new_label.global_position = Vector2(
		self.global_position.x,
		self.global_position.y - 40,
	)
	new_label.show_damage(damage)
