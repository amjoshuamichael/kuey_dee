extends SkeletonIK3D

@export var pull: Marker3D

@export var adjacent_leg1: SkeletonIK3D
@export var adjacent_leg2: SkeletonIK3D
@export var adjacent_leg3: SkeletonIK3D

func _ready():
	start()
	pass

const FOOT_BOUNCE = 0.15
const MOVE_SPEED = 0.02
const MOVEMENT_GAP = 0.3
const DIRE_MOVEMENT_GAP = 0.7

var moving = false
var snap_to_target = false

func _process(delta):
	if $"../../../../spider_model".snap_legs_to_target:
		get_node(target_node).position = pull.global_position
		return
	
	var dist_to_target = pull.global_position.distance_to(get_node(target_node).position)
	if (dist_to_target > MOVEMENT_GAP 
		and !moving
		and !adjacent_leg1.moving
		and !adjacent_leg2.moving
		and !adjacent_leg3.moving):
		var t = get_tree().create_tween()
		t.set_ease(Tween.EASE_IN_OUT)
		t.tween_property(get_node(target_node), 'position:y', pull.global_position.y + FOOT_BOUNCE, MOVE_SPEED / 2)
		t.tween_property(get_node(target_node), 'position:y', pull.global_position.y, MOVE_SPEED / 2).set_delay(MOVE_SPEED / 2)
		t.tween_property(get_node(target_node), "position:x", pull.global_position.x, MOVE_SPEED)
		t.tween_property(get_node(target_node), "position:z", pull.global_position.z, MOVE_SPEED)
		moving = true
		t.tween_callback(func setmovingfalse(): moving = false).set_delay(MOVE_SPEED)
	
	if dist_to_target > DIRE_MOVEMENT_GAP:
		get_node(target_node).position = pull.global_position
		
