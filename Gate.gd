# This script manages a gate which can restrict the passage of a ball

extends StaticBody2D

var raised = true

# Lower the gate so it won't obstruct the ball.
func lower():
	$CollisionShape2D.set_deferred("disabled", true)
	set_visible(false)
	raised = false

# Raise the gate so it can obstruct the ball.
func raise():
	$CollisionShape2D.set_deferred("disabled", false)
	set_visible(true)
	raised = true

# Identify whether the gate is raised or not.
func is_raised():
	return raised
