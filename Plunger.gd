# This code manages the plunger.

extends Node2D

# You can use the inspector to override the following:
# - the extension/retraction distance
# - the time it takes to pull the plunger to its full retraction
# - the time it takes for the plunger to snap back
# - the input control that pulls the plunger
export var full_extension = 50
export var pull_time = 1.0
export var release_time = 0.05
export var keycode = "ui_plunger"

var release_speed = 0.0

func _physics_process(delta):
	var y = $RigidBody2D.get_position().y
	if Input.is_action_pressed(keycode):
		# If the player is holding the pull key, slowly retract the plunger.
		if y < full_extension:
			y += (full_extension / pull_time) * delta
			if y > full_extension:
				y = full_extension
			$RigidBody2D.set_position(Vector2(0, y))
	else:
		# Otherwise allow the plunger to snap back.
		if y > 0.0:
			if release_speed == 0.0:
				release_speed = y / release_time
			y -= release_speed * delta
			if y <= 0.0:
				y = 0.0
				release_speed = 0.0
			$RigidBody2D.set_position(Vector2(0, y))
	if Input.is_action_just_released(keycode):
		# Play a sound the instant the player releases the control.
		$AudioStreamPlayer.play()
