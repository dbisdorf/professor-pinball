# This code manages the instruction card.

extends Sprite

const INVISIBLE_X = -448
const VISIBLE_X = 448
const IDLE_X = 1338
const SLIDE_SPEED = 20

var revealing = false
var concealing = false

func _process(delta):
	var card_position = get_position()
	if revealing and card_position.x > VISIBLE_X:
		# Slide the card in from the right if we're revealing it.
		card_position.x -= SLIDE_SPEED
		if card_position.x <= VISIBLE_X:
			card_position.x = VISIBLE_X
			revealing = false
		set_position(card_position)
	if concealing and card_position.x > INVISIBLE_X:
		# Slide the card off to the left if we're concealing it.
		card_position.x -= SLIDE_SPEED
		if card_position.x <= INVISIBLE_X:
			card_position.x = IDLE_X
			set_visible(false)
			concealing = false
		set_position(card_position)

# Call this function to reveal the card.
func reveal():
	if not is_visible() and not concealing:
		set_visible(true)
		revealing = true

# Call this function to conceal the card.
func conceal():
	if is_visible() and not revealing:
		concealing = true