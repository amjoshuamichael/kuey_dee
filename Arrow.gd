extends Node2D

@export var start: Vector2
@export var end: Vector2
@export var head_size: float
@export var color: Color

func _ready():
	$Line.default_color = color
	$Head.color = color
	
func _process(delta):
	if start == null or end == null:
		return
	
	$Line.points = [start, end  + (start - end).normalized() * 4]
	$Head.rotation = start.angle_to_point(end)
	$Head.position = end
	pass
