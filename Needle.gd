# This code manages the needle of a semicircular meter.

extends Sprite

var level = 0.0
var target = 0.0

const CONVERSION = 180.0
const JUMP_SPEED = 3.0
const RELAX_SPEED = 1.0

# The needle will jump up quickly to a higher position, 
# and fall down slowly to a lower position.
func _process(delta):
	if target > 0.0:
		if target > level:
			level += delta * JUMP_SPEED
			if level >= target:
				level = target
				target = 0.0
		elif target < level:
			level -= delta * JUMP_SPEED
			if level <= target:
				level = target
				target = 0.0
		else:
			target = 0.0
	else:
		if level > 0.0:
			level -= delta * RELAX_SPEED
			if level < 0.0:
				level = 0.0
	set_rotation_degrees(level * CONVERSION)

# Set the needle's desired position.
func set_level(new_level):
	if new_level < 0.0:
		target = 0.0
	elif new_level > 1.0:
		target = 1.0
	else:
		target = new_level
