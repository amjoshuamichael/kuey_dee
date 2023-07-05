extends Node2D

var l_points = []
var r_points = []
var player_position: Vector2
var refresh: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !refresh:
		return
	
	refresh = false
		
	var l_polygon_points = l_points.duplicate()
	for n in l_points.size():
		n = l_points.size() - n - 1
		l_polygon_points.push_back((r_points[n] + l_points[n]) / 2)
	
	var r_polygon_points = r_points.duplicate()
	for n in r_points.size():
		n = r_points.size() - n - 1
		r_polygon_points.push_back((l_points[n] + r_points[n]) / 2)
		
	$L.polygon = l_polygon_points
	$R.polygon = r_polygon_points
	
	$Arrow.start = player_position
	$Arrow.end = (l_points[0] + r_points[0]) / 2
