# This script manages a drop target.

extends RigidBody2D

var down = false

# Lower the drop target and play a sound.
func drop():
	$AudioStreamPlayer.play()
	$CollisionShape2D.call_deferred("set_disabled", true)
	$Sprite.set_visible(false)
	down = true

# Raise the drop target.
func raise():
	$CollisionShape2D.call_deferred("set_disabled", false)
	$Sprite.set_visible(true)
	down = false

# Identify whether the target is up or down.
func is_down():
	return down