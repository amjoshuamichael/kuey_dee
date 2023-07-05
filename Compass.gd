extends Node2D

const circle_points = 128

var end_position = null

var compass_position: Vector2 = Vector2.ZERO
var compass_scale: float = 0.0

func _ready():
	var angle = 0
	
	var points = []
	var uvs = []
	
	for n in circle_points:
		points.push_back(Vector2(sin(angle), cos(angle)))
		uvs.push_back((Vector2(sin(angle), cos(angle)) / 2 + Vector2(0.5, 0.5)) * $Circle.texture.width)
		
		angle += 2 * PI / circle_points
		
	$Circle.polygon = points
	$Circle.uv = uvs
	
func _process(_delta):
	if end_position:
		$Arrow.visible = true
		$Arrow.start = compass_position
		$Arrow.end = end_position
	else:
		$Arrow.visible = false
	
	$Circle.position = compass_position
	$Circle.scale = Vector2(compass_scale, compass_scale)
