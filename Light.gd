# This code manages a table light.

extends Sprite

var flashes = 0
var actual_time = 0

# By default, the light sprite is somewhat dark when it's "off" and fully bright when it's "on".
# You can override this in the inspector for a given light instance.
export var off_light = Color(1.0, 1.0, 1.0, 0.3)
export var on_light = Color(1.0, 1.0, 1.0, 1.0)

# Set the sprite to it's "off" shade to begin with.
func _ready():
	set_modulate(off_light)

# Switch to the "on" shade.
func switch_on():
	set_modulate(on_light)
	$Timer.stop()
	
# Switch to the "off" shade.
func switch_off():
	actual_time = 0
	set_modulate(off_light)
	$Timer.stop()

# Flash the light and then leave it on.
func flash_on():
	set_modulate(on_light)
	flashes = 6
	$Timer.set_one_shot(false)
	$Timer.start(0.2)

# Flash the light and then turn it off.
func flash_off():
	if get_modulate() == off_light:
		set_modulate(on_light)
		flashes = 5
	else:
		set_modulate(off_light)
		flashes = 6
	$Timer.set_one_shot(false)
	$Timer.start(0.2)

# Flash the light continuously.
# The first parameter is the duration of each on/off stage.
# The second (optional) parameter is the duration of the initial flash.
func flash(flash_time = 0.3, first_time = 0.0):
	set_modulate(on_light)
	flashes = -1
	$Timer.set_one_shot(false)
	if first_time:
		actual_time = flash_time
		$Timer.start(first_time)
	else:
		$Timer.start(flash_time)

# Flash the light only once, quickly.
func flash_once():
	set_modulate(on_light)
	flashes = -1
	$Timer.set_one_shot(true)
	$Timer.start(0.15)

# The timer manages transitions between on and off.
func _on_Timer_timeout():
	if get_modulate() != off_light:
		set_modulate(off_light)
	else:
		set_modulate(on_light)
	if actual_time:
		$Timer.start(actual_time)
		actual_time = 0
	if flashes > 0:
		flashes -= 1
		if flashes == 0:
			$Timer.stop()
