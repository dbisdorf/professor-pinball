extends AudioStreamPlayer

var eject_stream = preload("res://sound/eject.wav")
var award_stream = preload("res://sound/award.wav")
var lane_stream = preload("res://sound/lane.wav")
var drain_stream = preload("res://sound/drain.wav")
var save_stream = preload("res://sound/save.wav")
var loop_stream = preload("res://sound/loop.wav")
var startup_stream = preload("res://sound/toccata1.wav")
var begin_stream = preload("res://sound/toccata2.wav")
var bonus_stream = preload("res://sound/toccata3.wav")
var end_stream = preload("res://sound/toccata4.wav")
var jackpot_stream = preload("res://sound/jackpot.wav")
var new_ball_stream = preload("res://sound/new_ball.wav")
var challenge_stream = preload("res://sound/challenge.wav")
var wizard_stream = preload("res://sound/wizard.wav")

# This may not be optimal, but it's functional. This script 
# handles most award and event sounds. I didn't want to 
# create a separate AudioStreamPlayer for each of these sounds.

# Don't interrupt the jackpot sound.
func conditionally_play(new_stream):
	if get_stream() != jackpot_stream or not is_playing():
		set_stream(new_stream)
		play()

func play_begin():
	conditionally_play(begin_stream)
	
func play_eject():
	conditionally_play(eject_stream)
	
func play_award():
	conditionally_play(award_stream)
	
func play_lane():
	conditionally_play(lane_stream)
	
func play_drain():
	conditionally_play(drain_stream)
	
func play_save():
	conditionally_play(save_stream)

func play_startup():
	conditionally_play(startup_stream)

func play_bonus():
	conditionally_play(bonus_stream)

func play_end():
	conditionally_play(end_stream)

func play_loop():
	conditionally_play(loop_stream)

func play_jackpot():
	conditionally_play(jackpot_stream)

func play_new_ball():
	conditionally_play(new_ball_stream)

func play_challenge():
	conditionally_play(challenge_stream)

func play_wizard():
	conditionally_play(wizard_stream)