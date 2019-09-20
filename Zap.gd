extends Particles2D

var motion = Vector2(2000, 0)

func rotate(angle):
	motion = motion.rotated(angle)

func _process(delta):
	set_global_position(get_global_position() + (motion * delta))

func _on_Timer_timeout():
	queue_free()
