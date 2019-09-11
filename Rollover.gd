# This script manages a rollover which detects the passage of a ball in one direction.

extends Area2D

signal rollover_entered(body)

func _on_Rollover_body_entered(body):
	# Detecting the passage of the ball in only one direction requires some math.
	var ball_velocity = body.get_linear_velocity()
	# Rotate our frame of reference so the collision shape is horizontal for math purposes.
	var rotated_velocity = ball_velocity.rotated(0.0 - get_global_rotation())
	# With the frame of reference rotated, we want to raise a signal when the ball is moving "up."
	if rotated_velocity.y < 0.0:
		emit_signal("rollover_entered", body)
