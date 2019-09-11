# This code manages a brief particle effect which appears when a ball hits something interesting.

extends Particles2D

# Start emitting our impact particles.
func _ready():
	set_emitting(true)

# Change the particle color.
func set_color(new_color):
	var particle_material = get_process_material()
	particle_material.set_color(new_color)

# Destroy the particle system.
func _on_Timer_timeout():
	queue_free()
