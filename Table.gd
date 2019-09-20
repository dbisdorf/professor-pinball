# This script manages most of the table logic.

extends Node

# TODO - FEATURES

# TODO - GRAPHICS AND SOUND

# More flair for DMD frames
# Volume for song #3 still seems quieter than SFX volume
# Improve pixel precision for all collision shapes
# Color for the toy
# More graphic detail for the lower corner areas
# More impressive sounds/graphics for wizard mode (ball trail, flipper sounds)

# TODO - FIXES

# Align flippers with kickers
# Release ball more quickly when starting a timed event?
# "Failed to get modified time for ...particle.png"
# Clamp velocity (max = 4337?)
# Something Is Up with the collision shape of the left flipper. The ball sort of bumps over this flipper in rest state.

# TODO - BALANCE`

# Too easy to get stuck in bumpers

# TODO - POLISH

# Verify no horizontal collision edges from table walls
# Adjust scores for task difficulty
# Are exits just rollovers?
# Remove debug code
# Inspect all debugger warnings/errors
# DMD code needs serious refactoring

# TODO - TESTING

# What happens if you're only missing one victory (bumpers) and you repeat another (lanes)?

const HIGH_SCORE_FILE = "user://high_score"

# screen geometry constants
const WINDOW_SIZE = Vector2(896, 2016)
const BALL_ENTRY = Vector2(834, 1810)
const BALL_EJECT = Vector2(0, -2000)

# force and other values for bumpers, kickers, nudging
const RELEASE_FORCE = 750
const NUDGE_V_FORCE = 300
const NUDGE_H_FORCE = 300
const NUDGE_VIEW_OFFSET = 10
const FORCE_BUMPER = 700.0
const FORCE_KICKER = 1200.0

# score awards
const SCORE_BUMPER = 25
const SCORE_DROP = 50
const SCORE_DROP_ALL = 1000
const SCORE_KICKER = 10
const SCORE_LANE = 500
const SCORE_LANE_HUNT = 5000
const SCORE_TARGET_HUNT = 5000
const SCORE_ALL_BUMPERS = 5000
const SCORE_LOOP = 250
const SCORE_JACKPOT = 10000
const SCORE_WIZARD_LANE = 2500
const SCORE_BONUS = 100
const SCORE_SKILL_SHOT = 1000

# goals for game events
const EXTRA_BALL_GOAL = 100000
const BUMPER_PROGRESS = 10
const BUMPER_GOAL = 100

# bottom-of-screen needles hit their max when the ball reaches this velocity
const NEEDLE_MAX_VELOCITY = 2000.0

# timing for certain conditions
const OUT_TIME = 3.0
const BONUS_TIME = 5.0

# values used to track what mode the game is in
enum {
	MODE_ATTRACT,
	MODE_NORMAL,
	MODE_MULTIBALL,
	MODE_LANE_HUNT,
	MODE_TARGET_HUNT,
	MODE_WIZARD,
	MODE_GAME_OVER,
	MODE_NEW_HIGH,
	MODE_BALL_OUT,
	MODE_BONUS}

var rng = RandomNumberGenerator.new()
var ball_scene = preload("res://Ball.tscn")
var impact_scene = preload("res://Impact.tscn")
var score
var ball
var last_ball
var lit_lane
var save_lit
var save_next_ball
var special_lit
var skill_gate
var multiplier
var balls_queued
var balls_in_play
var mode
var lanes
var loops
var banks
var bumps
var lane_hunt_1
var lane_hunt_2
var lane_hunt_3
var targets_hunted
var lane_hunter_victory
var target_hunter_victory
var multiball_victory
var bumper_victory
var high_score
var debug_velocity = 0.0

func _ready():
	#Engine.set_time_scale(0.5) Uncomment this to slow the game down
	
	# The game starts at a low resolution so the splash screen will look correct.
	# These lines set us to the correct resolution.
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, WINDOW_SIZE)
	OS.set_window_fullscreen(true)
	
	# Read the high score file, or set up a new file.
	var high_score_file = File.new()
	if high_score_file.file_exists(HIGH_SCORE_FILE):
		high_score_file.open(HIGH_SCORE_FILE, File.READ)
		high_score = high_score_file.get_64()
	else:
		high_score_file.open(HIGH_SCORE_FILE, File.WRITE)
		high_score_file.store_64(0)
		high_score = 0
	high_score_file.close()
	$DMD.set_parameter("high_score", high_score)
	
	# Start up all other table systems.
	rng.randomize()
	$Toy.lower_all_gates()
	$AudioStreamPlayer.play_startup()
	attract(true)

func _process(delta):
	# Handle input from player.
	if Input.is_action_just_pressed("ui_start"):
		if get_tree().paused:
			get_tree().paused = false
			$DMD.set_paused(false)
		elif mode == MODE_ATTRACT:
			mode = MODE_NORMAL
			new_game()
	if Input.is_action_just_pressed("ui_nudge_up") and $NudgeUpTimer.is_stopped():
		nudge_up()
	if Input.is_action_just_pressed("ui_nudge_left") and $NudgeLeftTimer.is_stopped():
		nudge_left()
	if Input.is_action_just_pressed("ui_nudge_right") and $NudgeRightTimer.is_stopped():
		nudge_right()
	if Input.is_action_just_pressed("ui_pause"):
		if get_tree().paused:
			get_tree().quit()
		else:
			get_tree().paused = true
			$DMD.set_paused(true)
	if Input.is_action_just_pressed("ui_help"):
		if $Instructions.is_visible():
			$Instructions.conceal()
		else:
			$Instructions.reveal()
	
	# Set needles to reflect ball velocity.
	var balls = get_tree().get_nodes_in_group("balls")
	var max_x = 0.0
	var max_y = 0.0
	for ball in balls:
		var ball_velocity = ball.get_linear_velocity()
		if ball_velocity.length() > debug_velocity:
			debug_velocity = ball_velocity.length()
		if abs(ball_velocity.x) > max_x:
			max_x = abs(ball_velocity.x)
		if abs(ball_velocity.y) > max_y:
			max_y = abs(ball_velocity.y)
	$LeftNeedle.set_level(max_x / NEEDLE_MAX_VELOCITY)
	$RightNeedle.set_level(max_y / NEEDLE_MAX_VELOCITY)

# debug code debug code debug code
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_E:
				change_special()
			if event.scancode == KEY_W:
				lane_hunter_victory = true
				target_hunter_victory = true
				multiball_victory = true
				bumper_victory = true
				bumps = 110
				$TargetHuntVictoryLight.switch_on()
				$LaneHuntVictoryLight.switch_on()
				$MultiballVictoryLight.switch_on()
				$BumperVictoryLight.switch_on()
				check_wizard_mode()

# Set up the between-game attract mode effects.
func attract(startup = false):
	if startup:
		# If we just started up, we can't show the score from the prior game.
		$DMD.show_sequence($DMD.START_SEQ, true)
	else:
		# This DMD sequence includes the score from the prior game.
		$DMD.show_sequence($DMD.ATTRACT_SEQ, true)

	# Start all the lights flashing in a rotating sequence.
	mode = MODE_ATTRACT
	$LaneLight1.flash(3.0, 0.6)
	$LaneLight2.flash(3.0, 1.2)
	$LaneLight3.flash(3.0, 1.8)
	$LaneLight4.flash(3.0, 2.4)
	$LaneLight5.flash(3.0)
	$TargetHuntVictoryLight.flash(3.0, 0.75)
	$LaneHuntVictoryLight.flash(3.0, 1.5)
	$MultiballVictoryLight.flash(3.0, 2.25)
	$BumperVictoryLight.flash(3.0, 0)
	$LeftTargetLight.flash(3.0, 1.5)
	$RightTargetLight.flash(3.0)
	$SpecialLight1.flash(3.0, 1.0)
	$SpecialLight2.flash(3.0, 2.0)
	$SpecialLight3.flash(3.0)
	$X2Light.flash(3.0, 1.0)
	$X4Light.flash(3.0, 2.0)
	$X8Light.flash(3.0)
	$SaveLight.flash(3.0)
	$BumperLight1.flash(3.0, 1.0)
	$BumperLight2.flash(3.0, 2.0)
	$BumperLight3.flash(3.0)
	$LeftKickerLight.flash(3.0, 1.5)
	$RightKickerLight.flash(3.0)
	$SkillLight1.flash(3.0, 1.0)
	$SkillLight2.flash(3.0, 2.0)
	$SkillLight3.flash(3.0)

# Start a new game.
func new_game():
	# Reset game variables.
	score = 0
	ball = 1
	last_ball = 3
	lit_lane = 0
	save_lit = false
	save_next_ball = true
	special_lit = 1
	skill_gate = 0
	multiplier = 1
	balls_queued = 0
	mode = MODE_NORMAL
	lanes = 0
	loops = 0
	banks = 0
	targets_hunted = 0
	balls_in_play = 0
	bumps = 0
	lane_hunter_victory = false
	target_hunter_victory = false
	multiball_victory = false
	bumper_victory = false
	
	# Set up the table.
	$Toy.start()
	$DMD.set_parameter("score", score)
	$DMD.set_parameter("ball", ball)
	clear_all_lights()
	change_lit_lane(false)
	$SpecialLight1.switch_on()
	$ResetLeftTargets.start()
	$ResetRightTargets.start()
	new_ball()
	$AudioStreamPlayer.play_begin()

# Create a particle effect when the ball hits something interesting.
func impact(ball, color):
	var new_impact = impact_scene.instance()
	new_impact.set_global_position(ball.get_global_position())
	new_impact.set_color(color)
	call_deferred("add_child", new_impact)

# Common logic for hitting a bumper.
func bump(ball, bumper, force):
	impact(ball, Color(0.7, 0.7, 1.0))
	
	# Apply velocity due to impact from bumper.
	var from_bumper = ball.get_position() - bumper.get_position()
	ball.apply_central_impulse(from_bumper.normalized() * force)
	
	# Apply score and rules due to bumper hit.
	add_score(SCORE_BUMPER)
	bumps += 1
	if bumps >= BUMPER_GOAL:
		if bumper_victory == false:
			bumper_victory = true
			$AudioStreamPlayer.play_award()
			$DMD.set_parameter("reward", SCORE_ALL_BUMPERS)
			$DMD.show_once($DMD.DISPLAY_BUMPER_REWARD)
			$BumperVictoryLight.flash_on()
			check_wizard_mode()
	elif bumps % BUMPER_PROGRESS == 0:
		$DMD.set_parameter("progress", BUMPER_GOAL - bumps)
		$DMD.show_once($DMD.DISPLAY_BUMPER_PROGRESS)

# Common logic for hitting a kicker.
func kick(ball, kicker, force):
	add_score(SCORE_KICKER)
	impact(ball, Color(1.0, 1.0, 0.5))

	"""
	# Find offset from ball to kicker origin.
	var offset = ball.get_position() - kicker.get_position()
	# Rotate around kicker origin based on kicker orientation.
	var rotated_offset = offset.rotated(0 - kicker.get_global_rotation())
	# Determine whether ball is on the "kick" side.
	if rotated_offset.x > 0:
		# If so, apply impulse.
		ball.apply_central_impulse(Vector2.RIGHT.rotated(kicker.get_global_rotation()) * force)
	"""
	ball.apply_central_impulse(Vector2.RIGHT.rotated(kicker.get_global_rotation()) * force)

# Nudge the table up.
func nudge_up(first_impulse = true):
	var view_transform = get_viewport().get_canvas_transform()
	if first_impulse:
		# Initial nudge - the ball slides down.
		get_tree().call_group("balls", "apply_central_impulse", Vector2.DOWN * NUDGE_V_FORCE)
		view_transform.origin += Vector2.UP * NUDGE_VIEW_OFFSET
		$NudgeUpTimer.start()
	else:
		# Table bounces back - the ball slides up.
		get_tree().call_group("balls", "apply_central_impulse", Vector2.UP * NUDGE_V_FORCE)
		view_transform.origin += Vector2.DOWN * NUDGE_VIEW_OFFSET
	get_viewport().set_canvas_transform(view_transform)

# Nudge the table from the left side.
func nudge_left(first_impulse = true):
	var view_transform = get_viewport().get_canvas_transform()
	if first_impulse:
		# Initial nudge - the ball slides left.
		get_tree().call_group("balls", "apply_central_impulse", Vector2.LEFT * NUDGE_H_FORCE)
		view_transform.origin += Vector2.RIGHT * NUDGE_VIEW_OFFSET
		$NudgeLeftTimer.start()
	else:
		# Table bounces back - the ball slides right.
		get_tree().call_group("balls", "apply_central_impulse", Vector2.RIGHT * NUDGE_H_FORCE)
		view_transform.origin += Vector2.LEFT * NUDGE_VIEW_OFFSET
	get_viewport().set_canvas_transform(view_transform)

# Nudge the table from the right side.
func nudge_right(first_impulse = true):
	var view_transform = get_viewport().get_canvas_transform()
	if first_impulse:
		# Initial nudge - the ball slides right.
		get_tree().call_group("balls", "apply_central_impulse", Vector2.RIGHT * NUDGE_H_FORCE)
		view_transform.origin += Vector2.LEFT * NUDGE_VIEW_OFFSET
		$NudgeRightTimer.start()
	else:
		# Table bounces back - the ball slides left.
		get_tree().call_group("balls", "apply_central_impulse", Vector2.LEFT * NUDGE_H_FORCE)
		view_transform.origin += Vector2.RIGHT * NUDGE_VIEW_OFFSET
	get_viewport().set_canvas_transform(view_transform)

# Put a new ball in play.
func new_ball(eject = false):
	if mode != MODE_MULTIBALL:
		$DMD.show_and_keep($DMD.DISPLAY_SCORE)
		if save_next_ball:
			# Usually, if we just lost a ball, we'll turn on ball save for the new ball.
			save_next_ball = false
			save_lit = true
			$SaveLight.switch_on()
			$BallSaveTimer.start()
	# Put the ball on the table.
	var new_ball = ball_scene.instance()
	new_ball.set_global_position(BALL_ENTRY)
	if eject:
		# Sometimes we want to eject the ball automatically.
		new_ball.set_linear_velocity(BALL_EJECT)
	else:
		# But if we're not auto-ejecting the ball, we'll set up a skill shot opportunity.
		choose_skill_gate()
		$AudioStreamPlayer.play_new_ball()
	if (not eject) or (mode == MODE_MULTIBALL):
		balls_in_play += 1
	call_deferred("add_child", new_ball)

# Randomly pick a skill shot gate.
func choose_skill_gate():
	skill_gate = rng.randi_range(1, 3)
	match skill_gate:
		1:
			$SkillLight1.flash_on()
		2:
			$SkillLight2.flash_on()
		3:
			$SkillLight3.flash_on()
	$SkillShotTimer.start()

# Check if the ball hit the lit skill shot gate.
func check_skill_gate(gate_hit):
	if skill_gate == gate_hit:
		match skill_gate:
			1:
				$SkillLight1.flash_off()
			2:
				$SkillLight2.flash_off()
			3:
				$SkillLight3.flash_off()
		skill_gate = 0
		add_score(SCORE_SKILL_SHOT)
		$DMD.show_once($DMD.DISPLAY_SKILL_SHOT)
		$AudioStreamPlayer.play_award()
	else:
		clear_skill_gates()

# Turn off the skill shot gates.
func clear_skill_gates():
	skill_gate = 0
	$SkillLight1.switch_off()
	$SkillLight2.switch_off()
	$SkillLight3.switch_off()
	$SkillShotTimer.stop()

# Increment score, update DMD, and check if we earned an extra ball.
func add_score(points):
	score += points
	$DMD.set_parameter("score", score)
	check_extra_ball()

# These effects run when the ball passes through the upper loop.
func looped():
	$LoopLight.flash_off()
	if mode == MODE_MULTIBALL:
		# Score a jackpot if multiball is running.
		add_score(SCORE_JACKPOT)
		$DMD.show_once($DMD.DISPLAY_JACKPOT)
		$AudioStreamPlayer.play_jackpot()
	else:
		# Otherwise increment loops for end-of-ball bonus.
		loops += 1
		add_score(SCORE_LOOP)
		$DMD.show_once($DMD.DISPLAY_LOOP)
		$AudioStreamPlayer.play_loop()

# Check whether the player has earned an extra ball.
func check_extra_ball():
	if score >= EXTRA_BALL_GOAL and last_ball == 3:
		last_ball = 4
		$DMD.show_once($DMD.DISPLAY_EXTRA_BALL)
		$AudioStreamPlayer.play_jackpot()

# Check whether the player has triggered multiball.
func check_multiball():
	print("entering check_multiball")
	if $Toy.are_all_gates_raised():
		print("all gates are raised")
		halt_events()
		mode = MODE_MULTIBALL
		lit_lane = 0
		balls_queued = 3
		balls_in_play = 0
		save_lit = false
		$MultiballVictoryLight.flash_on()
		$DMD.show_once($DMD.DISPLAY_MULTIBALL)
		$LaneLight1.flash()
		$LaneLight3.flash()
		$SaveLight.switch_off()
		$BallSaveTimer.stop()
		$LaneLight1.switch_off()
		$LaneLight2.switch_off()
		$LaneLight3.switch_off()
		$LaneLight4.switch_off()
		$LaneLight5.switch_off()
		$Toy.flash()
		$AudioStreamPlayer.play_challenge()
	else:
		print("gates are not raised")
		$DMD.show_once($DMD.DISPLAY_LOCKED)
		$Toy.flash_off()
	print("starting BallEjectTimer")
	$BallEjectTimer.start()

# Change which lane is lit.
func change_lit_lane(score_lane = true):
	if score_lane:
		# If we're scoring this event, flash the hit lane.
		match lit_lane:
			1:
				$LaneLight1.flash_off()
			2:
				$LaneLight2.flash_off()
			3:
				$LaneLight3.flash_off()
			4:
				$LaneLight4.flash_off()
			5:
				$LaneLight5.flash_off()
	else:
		# Otherwise just switch off all the lanes.
		$LaneLight1.switch_off()
		$LaneLight2.switch_off()
		$LaneLight3.switch_off()
		$LaneLight4.switch_off()
		$LaneLight5.switch_off()
	var new_lit_lane = lit_lane
	while new_lit_lane == lit_lane:
		new_lit_lane = rng.randi_range(1, 5)
	lit_lane = new_lit_lane
	if score_lane:
		# If we're scoring this event, increment the lane counter for the end-of-ball bonus.
		lanes += 1
		add_score(SCORE_LANE)
		$DMD.show_once($DMD.DISPLAY_LANE_REWARD)
		$AudioStreamPlayer.play_lane()
	# Light up the new lane.
	match lit_lane:
		1:
			$LaneLight1.switch_on()
		2:
			$LaneLight2.switch_on()
		3:
			$LaneLight3.switch_on()
		4:
			$LaneLight4.switch_on()
		5:
			$LaneLight5.switch_on()

# If the player hit a lane during the lane hunt event, check if the event was completed.
func check_lane_hunt():
	$AudioStreamPlayer.play_lane()
	$DMD.show_once($DMD.DISPLAY_LANE_HUNTED)
	# If all the flashing lanes were hit, the event is complete.
	if lane_hunt_1 and lane_hunt_2 and lane_hunt_3:
		lane_hunter_victory = true
		$LaneHuntVictoryLight.flash_on()
		check_wizard_mode()
		add_score(SCORE_LANE_HUNT)
		$AudioStreamPlayer.play_award()
		$DMD.set_parameter("reward", SCORE_LANE_HUNT)
		$DMD.show_once($DMD.DISPLAY_LANE_HUNT_REWARD)
		$LaneHuntTimer.stop()
		mode = MODE_NORMAL
		change_lit_lane(false)
		change_special()

# If the player hits any lane during wizard mode, give an extra reward.
func wizard_lane():
	add_score(SCORE_WIZARD_LANE)
	$DMD.set_parameter("reward", SCORE_WIZARD_LANE)
	$DMD.show_once($DMD.DISPLAY_WIZARD_JACKPOT)
	$AudioStreamPlayer.play_jackpot()

# Switch which special reward is lit, in front of the capture lane.
func change_special():
	match special_lit:
		1:
			special_lit = 2
			$SpecialLight1.switch_off()
			$SpecialLight2.switch_on()
		2:
			special_lit = 3
			$SpecialLight2.switch_off()
			$SpecialLight3.switch_on()
		3:
			special_lit = 1
			$SpecialLight3.switch_off()
			$SpecialLight1.switch_on()

# Identify whether all events are complete.
func all_events_complete():
	return lane_hunter_victory and target_hunter_victory and multiball_victory and bumper_victory

# Get ready for wizard mode if all events are complete.
func check_wizard_mode():
	if all_events_complete():
		$SpecialLight1.flash()
		$SpecialLight2.flash()
		$SpecialLight3.flash()
		$Toy.raise_all_gates()
		$WizardReadyTimer.start()

# Start wizard mode.
func start_wizard_mode():
	$WizardReadyTimer.stop()
	$BallSaveTimer.stop()
	lit_lane = 0
	save_lit = false
	
	$DMD.show_once($DMD.DISPLAY_WIZARD)
	$LaneLight1.flash(0.2)
	$LaneLight2.flash(0.2)
	$LaneLight3.flash(0.2)
	$LaneLight4.flash(0.2)
	$LaneLight5.flash(0.2)
	$SpecialLight1.switch_off()
	$SpecialLight2.switch_off()
	$SpecialLight3.switch_off()	
	$TargetHuntVictoryLight.flash(1.0)
	$LaneHuntVictoryLight.flash(1.0, 2.0)
	$MultiballVictoryLight.flash(1.0)
	$BumperVictoryLight.flash(1.0, 2.0)
	$SaveLight.switch_on()
	$Toy.flash(1.0)
	
	mode = MODE_WIZARD
	$AudioStreamPlayer.play_wizard()
	$WizardModeTimer.start()
	$BallReleaseRightTimer.start(1.0)

# Turn off all the table lights.
func clear_all_lights():
	$SpecialLight1.switch_off()
	$SpecialLight2.switch_off()
	$SpecialLight3.switch_off()
	$LaneLight1.switch_off()
	$LaneLight2.switch_off()
	$LaneLight3.switch_off()
	$LaneLight4.switch_off()
	$LaneLight5.switch_off()
	$LaneHuntVictoryLight.switch_off()
	$TargetHuntVictoryLight.switch_off()
	$MultiballVictoryLight.switch_off()
	$BumperVictoryLight.switch_off()
	$X2Light.switch_off()
	$X4Light.switch_off()
	$X8Light.switch_off()
	$LeftTargetLight.switch_off()
	$RightTargetLight.switch_off()
	$SaveLight.switch_off()
	$Toy.switch_off()
	$BumperLight1.switch_off()
	$BumperLight2.switch_off()
	$BumperLight3.switch_off()
	$LeftKickerLight.switch_off()
	$RightKickerLight.switch_off()
	$SkillLight1.switch_off()
	$SkillLight2.switch_off()
	$SkillLight3.switch_off()

# Stop any active event.
func halt_events():
	match mode:
		MODE_MULTIBALL:
			$Toy.switch_off()
			$Toy.lower_all_gates()
		MODE_LANE_HUNT:
			$LaneLight1.switch_off()
			$LaneLight2.switch_off()
			$LaneLight3.switch_off()
			$LaneHuntTimer.stop()
			change_lit_lane(false)
			change_special()
		MODE_TARGET_HUNT:
			$DropTarget1.raise()
			$DropTarget2.raise()
			$DropTarget3.raise()
			$DropTarget4.raise()
			$DropTarget5.raise()
			$DropTarget6.raise()
			$TargetHuntTimer.stop()
			$LeftTargetLight.switch_off()
			$RightTargetLight.switch_off()
			change_special()
		MODE_WIZARD:
			lane_hunter_victory = false
			target_hunter_victory = false
			multiball_victory = false
			bumper_victory = false
			bumps = 0
			clear_all_lights()
			change_lit_lane(false)
			$WizardModeTimer.stop()
			$Toy.lower_all_gates()
			change_special()
	mode = MODE_NORMAL

# This function runs multiple times after a game is over.
func game_over():
	match mode:
		MODE_GAME_OVER:
			# After showing the game over message, show the new high score if appropriate.
			if score > high_score:
				high_score = score
				var high_score_file = File.new()
				high_score_file.open(HIGH_SCORE_FILE, File.WRITE_READ)
				high_score_file.store_64(high_score)
				high_score_file.close()
				$DMD.set_parameter("high_score", high_score)
				$DMD.show_and_keep($DMD.DISPLAY_NEW_HIGH_SCORE)
				$AudioStreamPlayer.play_jackpot()
				$GameOverTimer.start()
				mode = MODE_NEW_HIGH
			else:
				attract()
		MODE_NEW_HIGH:
			# After showing the new high score, fall back to the attract loop.
			attract()
		_:
			# If this is the first entry to this function, show the game over message.
			mode = MODE_GAME_OVER
			$WizardModeTimer.stop()
			$Toy.reset()
			$DMD.show_and_keep($DMD.DISPLAY_GAME_OVER)
			$AudioStreamPlayer.play_end()
			$GameOverTimer.start()

# These effects run when the ball drains.
func _on_Exit_body_entered(body):
	balls_in_play -= 1
	body.queue_free()
	if save_lit:
		# If ball save is lit, eject a replacement ball.
		save_lit = false
		$SaveLight.flash_off()
		$BallSaveTimer.stop()
		$BallEjectTimer.start()
		$DMD.show_once($DMD.DISPLAY_BALL_SAVED)
		$AudioStreamPlayer.play_save()
	elif mode == MODE_WIZARD:
		# If we're in wizard mode, eject a replacement ball.
		$SaveLight.flash_on()
		$BallEjectTimer.start()
	else:
		if mode == MODE_MULTIBALL:
			if balls_queued == 0 and balls_in_play == 1:
				# If we're in multiball and there's only one ball left, turn off multiball.
				halt_events()
				multiball_victory = true
				check_wizard_mode()
		else:
			# If we're not in multiball, that's the end of this ball.
			halt_events()
			$X2Light.switch_off()
			$X4Light.switch_off()
			$X8Light.switch_off()
			multiplier = 1
			ball += 1
			
			# Calculate and display the end-of-ball bonuses.
			var loops_bonus = loops * SCORE_BONUS
			var lanes_bonus = lanes * SCORE_BONUS
			var banks_bonus = banks * SCORE_BONUS
			var total_bonus = multiplier * (loops_bonus + lanes_bonus + banks_bonus)
			score += total_bonus
			$DMD.set_parameter("score", score)
			$DMD.set_parameter("ball", ball)
			$DMD.set_parameter("loops", loops)
			$DMD.set_parameter("loops_bonus", loops_bonus)
			$DMD.set_parameter("lanes", lanes)
			$DMD.set_parameter("lanes_bonus", lanes_bonus)
			$DMD.set_parameter("banks", banks)
			$DMD.set_parameter("banks_bonus", banks_bonus)
			$DMD.set_parameter("reward", total_bonus)
			$DMD.set_parameter("multiplier", multiplier)

			$DMD.show_and_keep($DMD.DISPLAY_BALL_LOST)
			save_next_ball = true
			mode = MODE_BALL_OUT
			$AudioStreamPlayer.play_drain()
			$BallLostTimer.start(OUT_TIME)
			print("max velocity = " + str(debug_velocity))
			debug_velocity = 0.0

# These effects run when the ball enters the capture lane.
func _on_BallCaptureRight_rollover_entered(body):
	body.queue_free()
	if mode == MODE_NORMAL:
		# If there isn't an event running, we'll issue a reward.
		if all_events_complete():
			# If we've beat all the events, start wizard mode.
			start_wizard_mode()
		else:
			# Otherwise issue the lit reward.
			$AudioStreamPlayer.play_award()
			match special_lit:
				1:
					# Reward number 1 is to increment the bonus multiplier.
					match multiplier:
						1:
							multiplier = 2
							$DMD.show_once($DMD.DISPLAY_X2)
							$X2Light.flash_on()
						2:
							multiplier = 4
							$DMD.show_once($DMD.DISPLAY_X4)
							$X2Light.switch_off()
							$X4Light.flash_on()
						4, 8:
							multiplier = 8
							$DMD.show_once($DMD.DISPLAY_X8)
							$X4Light.switch_off()
							$X8Light.flash_on()
					$BallReleaseRightTimer.start()
					change_special()
				2:
					# Reward number 2 is to start the lane hunt event.
					mode = MODE_LANE_HUNT
					lane_hunt_1 = false
					lane_hunt_2 = false
					lane_hunt_3 = false
					lit_lane = 0
					$LaneLight1.flash()
					$LaneLight2.flash()
					$LaneLight3.flash()
					$LaneLight4.switch_off()
					$LaneLight5.switch_off()
					$DMD.show_sequence($DMD.LANE_HUNT_SEQ)
					$SpecialLight2.flash()
					$BallReleaseRightTimer.start()
					$LaneHuntTimer.start()
				3:
					# Reward number 3 is to start the drop target hunt event.
					mode = MODE_TARGET_HUNT
					$DropTarget1.raise()
					$DropTarget2.raise()
					$DropTarget3.raise()
					$DropTarget4.raise()
					$DropTarget5.raise()
					$DropTarget6.raise()
					$DMD.show_sequence($DMD.TARGET_HUNT_SEQ)
					$SpecialLight3.flash()
					$LeftTargetLight.flash()
					$RightTargetLight.flash()
					$BallReleaseRightTimer.start()
					$TargetHuntTimer.start()
	else:
		# If there's an event in progress, just release the ball from the capture lane.
		$BallReleaseRightTimer.start(1.0)

# The following three functions react to hits against the three bumpers.
func _on_Bumper1_body_entered(body):
	$BumperLight1.flash_once()
	bump(body, $Bumper1, FORCE_BUMPER)

func _on_Bumper2_body_entered(body):
	$BumperLight2.flash_once()
	bump(body, $Bumper2, FORCE_BUMPER)

func _on_Bumper3_body_entered(body):
	$BumperLight3.flash_once()
	bump(body, $Bumper3, FORCE_BUMPER)

# The following three functions react to hits against the left drop targets.
func _on_DropTarget1_body_entered(body):
	impact(body, Color(1.0, 0.5, 1.0))
	$DropTarget1.drop()
	left_target_dropped()

func _on_DropTarget2_body_entered(body):
	impact(body, Color(1.0, 0.5, 1.0))
	$DropTarget2.drop()
	left_target_dropped()

func _on_DropTarget3_body_entered(body):
	impact(body, Color(1.0, 0.5, 1.0))
	$DropTarget3.drop()
	left_target_dropped()

# This logic is common to all drop targets on the left side.
func left_target_dropped():
	if mode == MODE_TARGET_HUNT:
		# If we're in the target hunt event, check if the event is complete.
		check_target_hunting()
	else:
		# Otherwise check if the player cleared all left-side drop targets.
		add_score(SCORE_DROP)
		if $DropTarget1.is_down() and $DropTarget2.is_down() and $DropTarget3.is_down():
			banks += 1
			add_score(SCORE_DROP_ALL)
			$AudioStreamPlayer.play_award()
			$ResetLeftTargets.start()
			$LeftTargetLight.flash_off()
			$DMD.show_once($DMD.DISPLAY_TARGET_BANK_REWARD)

# When this timer expires, pop up the targets on the left side.
func _on_ResetLeftTargets_timeout():
	$DropTarget1.raise()
	$DropTarget2.raise()
	$DropTarget3.raise()

# The following three functions react to hits against the right drop targets.
func _on_DropTarget4_body_entered(body):
	impact(body, Color(1.0, 0.5, 1.0))
	$DropTarget4.drop()
	right_target_dropped()

func _on_DropTarget5_body_entered(body):
	impact(body, Color(1.0, 0.5, 1.0))
	$DropTarget5.drop()
	right_target_dropped()

func _on_DropTarget6_body_entered(body):
	impact(body, Color(1.0, 0.5, 1.0))
	$DropTarget6.drop()
	right_target_dropped()

# This logic is common to all drop targets on the right side.
func right_target_dropped():
	if mode == MODE_TARGET_HUNT:
		# If we're in the target hunt event, check if the event is complete.
		check_target_hunting()
	else:
		# Otherwise check if the player cleared all right-side drop targets.
		add_score(SCORE_DROP)
		if $DropTarget4.is_down() and $DropTarget5.is_down() and $DropTarget6.is_down():
			banks += 1
			$AudioStreamPlayer.play_award()
			add_score(SCORE_DROP_ALL)
			$ResetRightTargets.start()
			$RightTargetLight.flash_off()
			$DMD.show_once($DMD.DISPLAY_TARGET_BANK_REWARD)

# Run these effects if the player completes the drop target hunt event.
func check_target_hunting():
	if $DropTarget1.is_down() and $DropTarget2.is_down() and $DropTarget3.is_down() and $DropTarget4.is_down() and $DropTarget5.is_down() and $DropTarget6.is_down():
		add_score(SCORE_TARGET_HUNT)
		$AudioStreamPlayer.play_award()
		$DMD.set_parameter("reward", SCORE_TARGET_HUNT)
		$DMD.show_once($DMD.DISPLAY_TARGET_HUNT_REWARD)
		target_hunter_victory = true
		$TargetHuntVictoryLight.flash_on()
		$LeftTargetLight.switch_off()
		$RightTargetLight.switch_off()
		change_special()
		mode = MODE_NORMAL
		$TargetHuntTimer.stop()
		$ResetLeftTargets.start()
		$ResetRightTargets.start()
		check_wizard_mode()

# When this timer expires, pop up the targets on the right side.
func _on_ResetRightTargets_timeout():
	$DropTarget4.raise()
	$DropTarget5.raise()
	$DropTarget6.raise()

# The next two functions manage hits against the lower kickers.
func _on_LKicker_body_entered(body):
	if mode == MODE_NORMAL and not all_events_complete():
		change_special()
	$LeftKickerLight.flash_once()
	kick(body, $LKicker, FORCE_KICKER)

func _on_RKicker_body_entered(body):
	if mode == MODE_NORMAL and not all_events_complete():
		change_special()
	$RightKickerLight.flash_once()
	kick(body, $RKicker, FORCE_KICKER)

# The next five functions run when the ball passes through lanes.
func _on_Lane1Rollover_rollover_entered(body):
	if mode == MODE_WIZARD:
		wizard_lane()
	elif mode == MODE_LANE_HUNT:
		if not lane_hunt_1:
			$LaneLight1.switch_off()
			lane_hunt_1 = true
			check_lane_hunt()
	elif lit_lane == 1:
		change_lit_lane()
	else:
		looped()

func _on_Lane2Rollover_rollover_entered(body):
	if mode == MODE_WIZARD:
		wizard_lane()
	elif mode == MODE_LANE_HUNT:
		if not lane_hunt_2:
			$LaneLight2.switch_off()
			lane_hunt_2 = true
			check_lane_hunt()
	elif lit_lane == 2:
		change_lit_lane()

func _on_Lane3Rollover_rollover_entered(body):
	if mode == MODE_WIZARD:
		wizard_lane()
	elif mode == MODE_LANE_HUNT:
		if not lane_hunt_3:
			$LaneLight3.switch_off()
			lane_hunt_3 = true
			check_lane_hunt()
	elif lit_lane == 3:
		change_lit_lane()
	else:
		looped()

func _on_Lane4Rollover_rollover_entered(body):
	if mode == MODE_WIZARD:
		wizard_lane()
	elif lit_lane == 4:
		change_lit_lane()

func _on_Lane5Rollover_rollover_entered(body):
	if mode == MODE_WIZARD:
		wizard_lane()
	elif lit_lane == 5:
		change_lit_lane()

# When this timer expires, release the ball from the capture lane.
func _on_BallReleaseRightTimer_timeout():
	var new_ball = ball_scene.instance()
	new_ball.set_global_position($BallCaptureRight.get_global_position())
	new_ball.set_linear_velocity(Vector2.DOWN.rotated($BallCaptureRight.get_rotation()) * RELEASE_FORCE)
	add_child(new_ball)
	$AudioStreamPlayer.play_eject()

# When this timer expires, forcefully eject the ball from the plunger lane.
func _on_BallEjectTimer_timeout():
	$AudioStreamPlayer.play_eject()
	new_ball(true)
	if mode == MODE_MULTIBALL and balls_queued > 0:
		balls_queued -= 1
		if balls_queued > 0:
			$BallEjectTimer.start(2.0)

# End the lane hunt when this timer expires.
func _on_LaneHuntTimer_timeout():
	$DMD.show_once($DMD.DISPLAY_LANE_HUNT_EXPIRED)
	halt_events()

# End the drop target hunt when this timer expires.
func _on_TargetHuntTimer_timeout():
	$DMD.show_once($DMD.DISPLAY_TARGET_HUNT_EXPIRED)
	halt_events()

# End wizard mode when this timer expires.
func _on_WizardModeTimer_timeout():
	halt_events()

# Turn off ball save when this timer expires.
func _on_BallSaveTimer_timeout():
	save_lit = false
	$SaveLight.flash_off()

# Advance the game-over logic when this timer expires.
func _on_GameOverTimer_timeout():
	game_over()

# Advance the lost-ball logic when this timer expires.
func _on_BallLostTimer_timeout():
	if mode == MODE_BALL_OUT:
		# If we've already shown the lost-ball graphic, proceed to end-of-ball bonus.
		mode = MODE_BONUS
		$DMD.show_sequence($DMD.BONUS_SEQ)
		$AudioStreamPlayer.play_bonus()
		$BallLostTimer.start(BONUS_TIME)
	else:
		# If we've finished showing bonuses, check whether the game is over.
		check_extra_ball()
		if ball > last_ball:
			game_over()
		else:
			mode = MODE_NORMAL
			new_ball()

# The following three functions allow the table to bounce back after a nudge.
func _on_NudgeLeftTimer_timeout():
	nudge_left(false)

func _on_NudgeRightTimer_timeout():
	nudge_right(false)

func _on_NudgeUpTimer_timeout():
	nudge_up(false)

# The following three functions react when the ball enters the rotating toy gates.
func _on_ToyRollover1_rollover_entered(body):
	print("ToyRollover1 hit")
	body.queue_free()
	$Toy.raise_gate(1)
	check_multiball()

func _on_ToyRollover2_rollover_entered(body):
	print("ToyRollover2 hit")
	body.queue_free()
	$Toy.raise_gate(2)
	check_multiball()

func _on_ToyRollover3_rollover_entered(body):
	print("ToyRollover3 hit")
	body.queue_free()
	$Toy.raise_gate(3)
	check_multiball()

# The following four functions react to the ball leaving the plunger lane,
# passing through the skill shot gates.
func _on_SkillRollover1_rollover_entered(body):
	check_skill_gate(1)

func _on_SkillRollover2_rollover_entered(body):
	check_skill_gate(2)

func _on_SkillRollover3_rollover_entered(body):
	check_skill_gate(3)

func _on_NoSkillRollover_rollover_entered(body):
	clear_skill_gates()

# Turn off skill shot lights when this timer expires.
func _on_SkillShotTimer_timeout():
	clear_skill_gates()

# Intermittently flash the window light in the upper left.
func _on_WindowTimer_timeout():
	$WindowLight.flash_off()

func _on_WizardReadyTimer_timeout():
	if mode in [MODE_NORMAL, MODE_LANE_HUNT, MODE_MULTIBALL, MODE_TARGET_HUNT]:
		$DMD.show_once($DMD.DISPLAY_WIZARD_READY)
