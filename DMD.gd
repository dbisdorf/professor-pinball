extends Node2D

# This logic and the associated graphic resources simulate a low-res dot matrix display.



# We're simulating a display with a resolution of 128x32.
const DMD_WIDTH = 128
const DMD_HEIGHT = 32
const DMD_RECT = Rect2(-64, -16, 128, 32)
const BLANK_COLOR = Color(0, 0, 0)

# The display can show code-driven text, or can show pre-drawn bitmaps.
enum {MODE_GRAPHICS, MODE_TEXT}

# These are the different items the display can show. Everything above
# DISPLAY_CANNED_TEXT is a bitmap. Everything below DISPLAY_CANNED_TEXT
# is code-generated text.
enum {
	DISPLAY_LANE_HUNTED,
	DISPLAY_X2,
	DISPLAY_X4,
	DISPLAY_X8,
	DISPLAY_LOCKED,
	DISPLAY_BALL_SAVED,
	DISPLAY_LANE_REWARD,
	DISPLAY_TITLE,
	DISPLAY_TARGET_HUNT,
	DISPLAY_LANE_HUNT,
	DISPLAY_WIZARD,
	DISPLAY_GAME_OVER,
	DISPLAY_EXTRA_BALL,
	DISPLAY_BALL_LOST,
	DISPLAY_MULTIBALL,
	DISPLAY_TARGET_BANK_REWARD,
	DISPLAY_LOOP,
	DISPLAY_JACKPOT,
	DISPLAY_WIZARD_JACKPOT,
	DISPLAY_TARGET_HUNT_REWARD,
	DISPLAY_BUMPER_REWARD,
	DISPLAY_LANE_HUNT_REWARD,
	DISPLAY_SKILL_SHOT,
	DISPLAY_CANNED_TEXT,
	DISPLAY_SCORE,
	DISPLAY_FINAL_SCORE,
	DISPLAY_HELP_KEY,
	DISPLAY_START_KEY,
	DISPLAY_LANE_HUNT_RULES,
	DISPLAY_TARGET_HUNT_RULES,
	DISPLAY_BUMPER_PROGRESS,
	DISPLAY_LANE_HUNT_EXPIRED,
	DISPLAY_TARGET_HUNT_EXPIRED,
	DISPLAY_HIGH_SCORE,
	DISPLAY_NEW_HIGH_SCORE,
	DISPLAY_LANE_BONUS,
	DISPLAY_LOOP_BONUS,
	DISPLAY_TARGET_BONUS,
	DISPLAY_TOTAL_BONUS,
	DISPLAY_WIZARD_READY}

# This dictionary gives the duration of each display, in seconds.
const DISPLAY_TIME = {
	DISPLAY_LANE_HUNTED: 2.0,
	DISPLAY_X2: 2.0,
	DISPLAY_X4: 2.5,
	DISPLAY_X8: 3.0,
	DISPLAY_LOCKED: 3.0,
	DISPLAY_BALL_SAVED: 2.0,
	DISPLAY_LANE_REWARD: 3.0,
	DISPLAY_TITLE: 2.0,
	DISPLAY_LANE_HUNT: 2.0,
	DISPLAY_TARGET_HUNT: 2.0,
	DISPLAY_WIZARD: 3.0,
	DISPLAY_GAME_OVER: 2.0,
	DISPLAY_EXTRA_BALL: 3.0,
	DISPLAY_BALL_LOST: 2.0,
	DISPLAY_MULTIBALL: 3.0,
	DISPLAY_TARGET_BANK_REWARD: 2.0,
	DISPLAY_LOOP: 2.0,
	DISPLAY_JACKPOT: 3.0,
	DISPLAY_WIZARD_JACKPOT: 2.0,
	DISPLAY_SCORE: 3.0,
	DISPLAY_FINAL_SCORE: 3.0,
	DISPLAY_HELP_KEY: 2.0,
	DISPLAY_START_KEY: 2.0,
	DISPLAY_LANE_HUNT_RULES: 2.0,
	DISPLAY_LANE_HUNT_REWARD: 3.0,
	DISPLAY_SKILL_SHOT: 2.0,
	DISPLAY_TARGET_HUNT_RULES: 2.0,
	DISPLAY_TARGET_HUNT_REWARD: 3.0,
	DISPLAY_BUMPER_PROGRESS: 3.0,
	DISPLAY_BUMPER_REWARD: 3.0,
	DISPLAY_LANE_HUNT_EXPIRED: 3.0,
	DISPLAY_TARGET_HUNT_EXPIRED: 3.0,
	DISPLAY_HIGH_SCORE: 2.0,
	DISPLAY_NEW_HIGH_SCORE: 3.0,
	DISPLAY_LANE_BONUS: 1.0,
	DISPLAY_LOOP_BONUS: 1.0,
	DISPLAY_TARGET_BONUS: 1.0,
	DISPLAY_TOTAL_BONUS: 2.0,
	DISPLAY_WIZARD_READY: 3.0}

# This dictionary gives the priority of each display. A low-priority
# display will not interrupt a high-priority display.
const DISPLAY_PRIORITY = {
	DISPLAY_LANE_HUNTED: 0,
	DISPLAY_X2: 3,
	DISPLAY_X4: 3,
	DISPLAY_X8: 3,
	DISPLAY_LOCKED: 0,
	DISPLAY_BALL_SAVED: 10,
	DISPLAY_LANE_REWARD: 1,
	DISPLAY_TITLE: 0,
	DISPLAY_LANE_HUNT: 3,
	DISPLAY_TARGET_HUNT: 3,
	DISPLAY_WIZARD: 5,
	DISPLAY_GAME_OVER: 0,
	DISPLAY_EXTRA_BALL: 10,
	DISPLAY_BALL_LOST: 50,
	DISPLAY_MULTIBALL: 5,
	DISPLAY_TARGET_BANK_REWARD: 0,
	DISPLAY_LOOP: 0,
	DISPLAY_JACKPOT: 2,
	DISPLAY_WIZARD_JACKPOT: 3,
	DISPLAY_SCORE: 0,
	DISPLAY_FINAL_SCORE: 0,
	DISPLAY_HELP_KEY: 0,
	DISPLAY_START_KEY: 0,
	DISPLAY_LANE_HUNT_RULES: 0,
	DISPLAY_LANE_HUNT_REWARD: 3,
	DISPLAY_SKILL_SHOT: 0,
	DISPLAY_TARGET_HUNT_RULES: 0,
	DISPLAY_TARGET_HUNT_REWARD: 3,
	DISPLAY_BUMPER_PROGRESS: 0,
	DISPLAY_BUMPER_REWARD: 3,
	DISPLAY_LANE_HUNT_EXPIRED: 3,
	DISPLAY_TARGET_HUNT_EXPIRED: 3,
	DISPLAY_HIGH_SCORE: 0,
	DISPLAY_NEW_HIGH_SCORE: 0,
	DISPLAY_LANE_BONUS: 0,
	DISPLAY_LOOP_BONUS: 0,
	DISPLAY_TARGET_BONUS: 0,
	DISPLAY_TOTAL_BONUS: 0,
	DISPLAY_WIZARD_READY: 3}

# Certain displays appear in loops or in fixed sequences.
const START_SEQ = [DISPLAY_TITLE, DISPLAY_HELP_KEY, DISPLAY_START_KEY, DISPLAY_HIGH_SCORE]
const ATTRACT_SEQ = [DISPLAY_FINAL_SCORE, DISPLAY_TITLE, DISPLAY_HELP_KEY, DISPLAY_START_KEY, DISPLAY_HIGH_SCORE]
const LANE_HUNT_SEQ = [DISPLAY_LANE_HUNT, DISPLAY_LANE_HUNT_RULES]
const TARGET_HUNT_SEQ = [DISPLAY_TARGET_HUNT, DISPLAY_TARGET_HUNT_RULES]
const BONUS_SEQ = [DISPLAY_LANE_BONUS, DISPLAY_LOOP_BONUS, DISPLAY_TARGET_BONUS, DISPLAY_TOTAL_BONUS]

var dmd_texture = preload("res://graphics/dmd-animate.png")
var font
var font_texture = preload("res://graphics/font.png")
var upper_text
var lower_text
var upper_draw = Vector2(0, -14)
var lower_draw = Vector2(0, 2)
var texture_draw = Rect2(0, 0, DMD_WIDTH, DMD_HEIGHT)
var mode = 0
var displaying = -1
var parameters = {}
var repeat = false
var sequence = []
var sequence_index = 0
var paused = false
var scroll_adjust = 0

# There is probably a better way to do this, but this didn't require much
# thought, and it works. We're mapping characters to specific positions
# within the font bitmap.
func _ready():
	font = BitmapFont.new()
	font.add_texture(font_texture)
	font.set_height(12)
	
	font.add_char(KEY_A, 0, Rect2(0, 0, 8, 12))
	font.add_char(KEY_B, 0, Rect2(8, 0, 8, 12))
	font.add_char(KEY_C, 0, Rect2(16, 0, 8, 12))
	font.add_char(KEY_D, 0, Rect2(24, 0, 8, 12))
	font.add_char(KEY_E, 0, Rect2(32, 0, 8, 12))
	font.add_char(KEY_F, 0, Rect2(40, 0, 8, 12))
	font.add_char(KEY_G, 0, Rect2(48, 0, 8, 12))
	
	font.add_char(KEY_H, 0, Rect2(0, 12, 8, 12))
	font.add_char(KEY_I, 0, Rect2(8, 12, 8, 12))
	font.add_char(KEY_J, 0, Rect2(16, 12, 8, 12))
	font.add_char(KEY_K, 0, Rect2(24, 12, 8, 12))
	font.add_char(KEY_L, 0, Rect2(32, 12, 8, 12))
	font.add_char(KEY_M, 0, Rect2(40, 12, 8, 12))
	font.add_char(KEY_N, 0, Rect2(48, 12, 8, 12))

	font.add_char(KEY_O, 0, Rect2(0, 24, 8, 12))
	font.add_char(KEY_P, 0, Rect2(8, 24, 8, 12))
	font.add_char(KEY_Q, 0, Rect2(16, 24, 8, 12))
	font.add_char(KEY_R, 0, Rect2(24, 24, 8, 12))
	font.add_char(KEY_S, 0, Rect2(32, 24, 8, 12))
	font.add_char(KEY_T, 0, Rect2(40, 24, 8, 12))
	font.add_char(KEY_U, 0, Rect2(48, 24, 8, 12))

	font.add_char(KEY_V, 0, Rect2(0, 36, 8, 12))
	font.add_char(KEY_W, 0, Rect2(8, 36, 8, 12))
	font.add_char(KEY_X, 0, Rect2(16, 36, 8, 12))
	font.add_char(KEY_Y, 0, Rect2(24, 36, 8, 12))
	font.add_char(KEY_Z, 0, Rect2(32, 36, 8, 12))
	font.add_char(KEY_0, 0, Rect2(40, 36, 8, 12))
	font.add_char(KEY_1, 0, Rect2(48, 36, 8, 12))

	font.add_char(KEY_2, 0, Rect2(0, 48, 8, 12))
	font.add_char(KEY_3, 0, Rect2(8, 48, 8, 12))
	font.add_char(KEY_4, 0, Rect2(16, 48, 8, 12))
	font.add_char(KEY_5, 0, Rect2(24, 48, 8, 12))
	font.add_char(KEY_6, 0, Rect2(32, 48, 8, 12))
	font.add_char(KEY_7, 0, Rect2(40, 48, 8, 12))
	font.add_char(KEY_8, 0, Rect2(48, 48, 8, 12))

	font.add_char(KEY_9, 0, Rect2(0, 60, 8, 12))
	font.add_char(KEY_COMMA, 0, Rect2(8, 60, 8, 12))
	font.add_char(KEY_COLON, 0, Rect2(16, 60, 8, 12))
	font.add_char(KEY_EXCLAM, 0, Rect2(24, 60, 8, 12))
	
	font.add_char(KEY_SPACE, 0, Rect2(48, 72, 8, 12))

# there was a bug where the Wizard mode line keept showing, even after a new game.
# this should fix any bugs related to that
func DMDRESET():
	displaying = 0
	scroll_adjust = 0
	#other stuff in the future ig
	return

func _draw():
	draw_rect(DMD_RECT, BLANK_COLOR, true)
	if paused:
		# If the game is paused, just draw the pause text.
		draw_string(font, Vector2(get_starting_x("PAUSED"), upper_draw.y) , "PAUSED")
		draw_string(font, Vector2(get_starting_x("ENTER TO RESUME"), lower_draw.y) , "ENTER TO RESUME")
	else:
		# Otherwise, show text or bitmaps as appropriate.
		match mode:
			MODE_GRAPHICS:
				draw_texture_rect_region(dmd_texture, DMD_RECT, texture_draw)
			MODE_TEXT:
				draw_string(font, upper_draw, upper_text)
				draw_string(font, lower_draw, lower_text)

# Set the pause mode for the display.
func set_paused(is_paused):
	paused = is_paused
	update()

# For a given string, determine the leftmost X coordinate.
func get_starting_x(text):
	return 0 - ((len(text) * 8) / 2)

# Set the text for the top line of the display.
func set_upper_text(new_text):
	upper_text = new_text
	upper_draw.x = get_starting_x(upper_text)
	update()

# Set the text for the bottom line of the display.
func set_lower_text(new_text):
	lower_text = new_text
	lower_draw.x = get_starting_x(lower_text)
	update()

# Some text messages include parameters, such as score or ball number.
func set_parameter(param_name, param_value):
	parameters[param_name] = param_value
	format_text()

# Concatenate a quantity and a noun, and make the noun plural if necessary.
func pluralize(quantity, word):
	if quantity != 1:
		return str(quantity) + " " + word + "S"
	return str(quantity) + " " + word

# Assemble text for the display.
func format_text():
	match displaying:
		DISPLAY_SCORE:
			set_upper_text(str(parameters["score"]))
			set_lower_text("BALL " + str(parameters["ball"]))
		DISPLAY_FINAL_SCORE:
			set_upper_text("FINAL SCORE")
			set_lower_text(str(parameters["score"]))
		DISPLAY_HELP_KEY:
			set_upper_text("PRESS I FOR")
			set_lower_text("INSTRUCTIONS")
		DISPLAY_START_KEY:
			set_upper_text("PRESS ENTER")
			set_lower_text("TO BEGIN")
		DISPLAY_LANE_HUNT_RULES:
			set_upper_text("SHOOT ALL")
			set_lower_text("FLASHING LANES")
		DISPLAY_TARGET_HUNT_RULES:
			set_upper_text("CLEAR BOTH")
			set_lower_text("POWER BANKS")
		DISPLAY_BUMPER_PROGRESS:
			set_upper_text(pluralize(parameters["progress"], "BUMPER") + " FOR")
			set_lower_text("BREAKTHROUGH")
		DISPLAY_LANE_HUNT_EXPIRED:
			set_upper_text("OUT OF")
			set_lower_text("TIME")
		DISPLAY_TARGET_HUNT_EXPIRED:
			set_upper_text("OUT OF")
			set_lower_text("TIME")
		DISPLAY_HIGH_SCORE:
			set_upper_text("HIGH SCORE")
			set_lower_text(str(parameters["high_score"]))
		DISPLAY_NEW_HIGH_SCORE:
			set_upper_text("NEW HIGH SCORE!")
			set_lower_text(str(parameters["high_score"]))
		DISPLAY_LANE_BONUS:
			set_upper_text(pluralize(parameters["lanes"], "LIT LANE"))
			set_lower_text(str(parameters["lanes_bonus"]) + " POINTS")
		DISPLAY_LOOP_BONUS:
			set_upper_text(pluralize(parameters["loops"], "LOOP"))
			set_lower_text(str(parameters["loops_bonus"]) + " POINTS")
		DISPLAY_TARGET_BONUS:
			set_upper_text(pluralize(parameters["banks"], "POWER BANK"))
			set_lower_text(str(parameters["banks_bonus"]) + " POINTS")
		DISPLAY_TOTAL_BONUS:
			if parameters["multiplier"] == 1:
				set_upper_text("TOTAL BONUS")
			else:
				set_upper_text("TOTAL BONUS X" + str(parameters["multiplier"]))
			set_lower_text(str(parameters["reward"]))
		DISPLAY_WIZARD_READY:
			set_upper_text("SHOOT FLASHING")
			set_lower_text("LANE FOR EUREKA")

# Internal common display logic. Don't call this from outside this script.
func show_something(display_number, and_keep = false):
	displaying = display_number
	if display_number < DISPLAY_CANNED_TEXT:
		# If we're showing a bitmap, figure out where it is in the texture and display it.
		# This is where the bitmap is shown, bitmap updates on timer timeout
		mode = MODE_GRAPHICS
		texture_draw.position.y = DMD_HEIGHT * display_number
		texture_draw.position.x = DMD_WIDTH
		scroll_adjust = 0
		$BMPUpdate.start()
		update()
	else:
		# If we're showing text, construct it from strings and display it.
		mode = MODE_TEXT
		format_text()
	if sequence:
		# If we're showing a sequence, set a timer to move to the next display.
		$DMDTimer.set_one_shot(false)
		$DMDTimer.start(DISPLAY_TIME[display_number])
	elif and_keep:
		# If we're supposed to keep this display on-screen, turn off the timer.
		$DMDTimer.stop()
	else:
		# If we're not supposed to keep this on-screen, set a timer.
		$DMDTimer.set_one_shot(true)
		$DMDTimer.start(DISPLAY_TIME[display_number])

# Call this function to briefly display a message.
func show_once(display_number):
	if DISPLAY_PRIORITY[display_number] >= DISPLAY_PRIORITY[displaying]:
		sequence = []
		show_something(display_number)

# Call this function to display a message and leave it on the screen.
func show_and_keep(display_number):
	if DISPLAY_PRIORITY[display_number] >= DISPLAY_PRIORITY[displaying]:
		sequence = []
		show_something(display_number, true)

# Call this function to start a sequence, and optionally loop it.
func show_sequence(new_sequence = [], and_repeat = false):
	repeat = and_repeat
	sequence = new_sequence
	sequence_index = 0
	show_something(sequence[0])

# This timer expires after the desired display has been on-screen for a few seconds.
func _on_DMDTimer_timeout():
	if sequence:
		# If we're displaying a sequence, move to the next step.
		sequence_index += 1
		if sequence_index == len(sequence):
			if not repeat:
				# If we're stopping the sequence, display the score.
				show_something(DISPLAY_SCORE, true)
				$DMDTimer.stop()
			else:
				# If we're looping the sequence, start over.
				sequence_index = 0
				show_something(sequence[sequence_index])
		else:
			show_something(sequence[sequence_index])
	else:
		# If we're not displaying a sequence, go back to showing the score.
		show_something(DISPLAY_SCORE, true)
	

# this function updates a baked in image for the pourpose of an animation
# the function is built around dispalying one of 4 images for each of the event images


func _on_BMPUpdate_timeout():
	if scroll_adjust > 4:
		scroll_adjust = 0
	texture_draw.position.x = DMD_WIDTH * scroll_adjust
	scroll_adjust = scroll_adjust + 1
	$BMPUpdate.start()
	update()
