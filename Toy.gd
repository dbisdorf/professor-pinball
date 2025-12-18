# This script manages the rotating toy in the center of the table.

extends RigidBody2D

const SLOW_SPEED = 1
const FAST_SPEED = 5

var speed = 0
var resetting = false
var gate_1_raised
var agte_2_raised
var gate_3_raised

func _process(delta):
	if speed > 0:
		# Rotate the toy.
		var new_rotation = get_rotation_degrees() + speed
		if new_rotation >= 360:
			# If we've gone past the starting orientation...
			if resetting:
				# Halt the toy if we're trying to reset it.
				new_rotation = 0
				speed = 0
				resetting = false
			else:
				new_rotation -= 360
		set_rotation_degrees(new_rotation)

# Start the toy rotating slowly.
func start():
	speed = SLOW_SPEED

# Stop the toy.
func stop():
	speed = 0

# Lower the toy's three gates.
func lower_all_gates():
	$ToyGate1.lower()
	$ToyGate2.lower()
	$ToyGate3.lower()

# Raise all three gates.
func raise_all_gates():
	$ToyGate1.raise()
	$ToyGate2.raise()
	$ToyGate3.raise()	

# Tell the toy to reset itself.
func reset():
	lower_all_gates()
	resetting = true
	speed = FAST_SPEED

# Raise one of the three gates.
func raise_gate(gate):
	$AudioStreamPlayer.play()
	match gate:
		1:
			$ToyGate1.raise()
		2:
			$ToyGate2.raise()
		3:
			$ToyGate3.raise()

# Identify whether all three gates are raised.
func are_all_gates_raised():
	return $ToyGate1.is_raised() and $ToyGate2.is_raised() and $ToyGate3.is_raised()

# Make the toy's light flash.
func flash(flash_time = 0.3, first_time = 0.0):
	$Light.flash(flash_time, first_time)

# Make the toy's light flash a few times, then switch off.
func flash_off():
	$Light.flash_off()

# Just switch off the toy's light.
func switch_off():
	$Light.switch_off()
