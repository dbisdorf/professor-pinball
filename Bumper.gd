# This script manages a round bumper.

extends RigidBody2D

# Play a sound effect when the ball hits the bumper.
func _on_Bumper_body_entered(body):
	$AudioStreamPlayer.play()
