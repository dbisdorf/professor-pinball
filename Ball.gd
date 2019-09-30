# This script manages a ball.

extends RigidBody2D

const MIN_SOUND_VELOCITY = 500.0
const MAX_SOUND_VELOCITY = 1000.0
const MIN_VOLUME = -40.0
const MAX_VOLUME = -20.0
const MIN_TRAIL_VELOCITY = 2000.0

# Turn on the particle trail when the ball appears.
func _ready():
	$CPUParticles2D.set_emitting(false)

# Turn the particle trail on or off based on ball velocity.
func _process(delta):
	var velocity = get_linear_velocity().length()
	$CPUParticles2D.set_emitting(velocity > MIN_TRAIL_VELOCITY)

"""
If you're testing a table and you need to put the ball in a specific 
place, uncomment this code and set the origin/velocity appropriately. 
Then, during play, just hold Q to put the ball where you want it.
func _integrate_forces(state):
	if Input.is_key_pressed(KEY_Q):
		var where = state.get_transform()
		where.origin = Vector2(700, 1200)
		state.set_transform(where)
		state.set_linear_velocity(Vector2(100, -1000))
"""
