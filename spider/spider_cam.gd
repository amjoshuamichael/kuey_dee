extends Camera3D

@export var spider: Node3D

func _process(delta):
	position.x = spider.position.x
	position.y = spider.position.y + .1 - spider.offset_y
	pass
