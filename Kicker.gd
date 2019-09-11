# This code manages a straight-line kicker surface.

extends RigidBody2D

# Play a sound effect when the ball hits the kicker.
func _on_Kicker_body_entered(body):
	$AudioStreamPlayer.play()
