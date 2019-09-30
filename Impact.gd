# This code manages a brief particle effect which appears when a ball hits something interesting.

extends CPUParticles2D

# Change the particle color.

# This isn't perfect. When we alter the particle material, every instance of the
# particle system gets the change, even an instance we created previously.
# For example, if we created one instance of a green particle spray, and then
# created a red particle spray while the green particles are still active,
# the green particle spray will turn red. This isn't a serious problem, as you
# have to have sharp eyes to notice when this happens.

# Also, any change we make to the material will persist to subsequent particle 
# instances, which means we can't assume a given instance will have the default 
# parameters we started the game with. This means we have to set certain
# parameters every time, even if we appear to be setting them to the default.

func setup(new_color, high_impact = false):
	#var particle_material = get_process_material()
	set_color(new_color)
	if high_impact:
		set_amount(128)
		set_lifetime(1.0)
		set_param(ParticlesMaterial.PARAM_HUE_VARIATION, 1.0)
		set_param_randomness(ParticlesMaterial.PARAM_HUE_VARIATION, 1.0)
		$AudioStreamPlayer.play()
	else:
		set_amount(64)
		set_lifetime(0.25)
		set_param(ParticlesMaterial.PARAM_HUE_VARIATION, 0.0)
		set_param_randomness(ParticlesMaterial.PARAM_HUE_VARIATION, 0.0)
	set_emitting(true)
	$Timer.start(get_lifetime())

# Destroy the particle system.
func _on_Timer_timeout():
	queue_free()
