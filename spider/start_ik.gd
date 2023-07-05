extends SkeletonIK3D

@export var pull: Marker3D

func _ready():
	start()
	pass

func _process(_delta):
	if pull.global_position.distance_to(get_node(target_node).position) > 0.5:
		get_node(target_node).position = pull.global_position
