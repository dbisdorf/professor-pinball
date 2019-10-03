extends Node2D

# The length of a lightning bolt segment.
const POINT_STEP = Vector2(120, 0)

var rng = RandomNumberGenerator.new()
var base_rotation
var point_array
var zap_color = Color(1.0, 1.0, 1.0)
#var glow_color = Color(0.6, 0.6, 1.0, 0.5)
var glow_color = Color(0.7, 0.7, 0.0, 0.5)

# Choose the angle of the lightning bolt.
func _ready():
	rng.randomize()
	base_rotation = rng.randf_range(0.0, 2 * PI)

# Randomize the jagged segments of the lightning bolt.
func _process(delta):
	point_array = PoolVector2Array()
	var prior_point = Vector2(0, 0)
	var point
	for point_index in range(1, 10):
		point_array.push_back(prior_point)
		point = POINT_STEP.rotated(base_rotation + rng.randf_range(0.0, 0.2)) * point_index
		point_array.push_back(point)
		prior_point = point
	update()

# Draw the lightning bolt.
func _draw():
	if point_array:
		draw_polyline(point_array, glow_color, 40.0)
		draw_polyline(point_array, zap_color, 8.0)

func _on_Timer_timeout():
	queue_free()
