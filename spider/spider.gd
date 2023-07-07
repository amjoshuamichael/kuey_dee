extends Node3D

@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0

var lb_targ: Marker3D = null
var lm_targ: Marker3D = null
var lf_targ: Marker3D = null
var rb_targ: Marker3D = null
var rm_targ: Marker3D = null
var rf_targ: Marker3D = null

const MAX_LEG_WIDTH = 0.8
const JUMPING_LEG_WIDTH = 0.3
const JUMPING_LEG_HEIGHT = 0.6
const MAX_LEG_LENGTH = 0.8
var leg_width = MAX_LEG_WIDTH
var leg_length = MAX_LEG_LENGTH
const overshoot = -0.2
const movement_dip = -0.15
const dip_speed = 0.2

var target_x: float = 0.0
var x_velocity: float = 0.0
var y_velocity: float = 0.0
var is_on_floor: bool = false
var dist_to_floor: float = 0.0

const offset_z: float = 0.1

var offset_y: float = 0.0
var leg_offset_y: float = 0.0

var target_y_rotation: float = face_camera_offset
var rotation_speed: float = 0.2

var snap_legs_to_target: bool = false

const face_camera_offset: float = 45

func _ready():
	lb_targ = $LBTarget
	lm_targ = $LMTarget
	lf_targ = $LFTarget
	rb_targ = $RBTarget
	rm_targ = $RMTarget
	rf_targ = $RFTarget
	pass

func _process(delta):
	var delta_x = target_x - global_position.x
	global_position.x += delta_x
	$Marks.global_position.x -= delta_x
	target_x += 0.003
	
	if x_velocity > 0:
		target_y_rotation = face_camera_offset
	elif x_velocity < 0:
		target_y_rotation = -face_camera_offset
	
	rotation_degrees.y = lerp(rotation_degrees.y, target_y_rotation, rotation_speed)
	
	leg_offset_y = 0.0 if is_on_floor else min((dist_to_floor - 10) / 24, JUMPING_LEG_HEIGHT)
	
	set_pos(lb_targ, Vector3(leg_width, 0, overshoot + leg_length))
	set_pos(lm_targ, Vector3(leg_width, 0, overshoot))
	set_pos(lf_targ, Vector3(leg_width, 0, overshoot - leg_length))
	set_pos(rb_targ, Vector3(-leg_width, 0, overshoot + leg_length))
	set_pos(rm_targ, Vector3(-leg_width, 0, overshoot))
	set_pos(rf_targ, Vector3(-leg_width, 0, overshoot - leg_length))
	
	if is_on_floor:
		var target_offset_y = 0.0 if abs(x_velocity) < 0.2 else movement_dip
		offset_y = lerp(offset_y, target_offset_y, dip_speed)
		global_position.y = offset_y
		leg_width = MAX_LEG_WIDTH
		snap_legs_to_target = false
	else:
		var leg_width_target = clamp(
			(-dist_to_floor + 10) / 50 + MAX_LEG_WIDTH, 
			JUMPING_LEG_WIDTH, 
			MAX_LEG_WIDTH
		)
		leg_width = lerp(leg_width, leg_width_target, 16 * delta)
		snap_legs_to_target = true

func set_pos(targ, pos_offset):
	var rotated = pos_offset.rotated(Vector3.UP, rotation.y)
	rotated.x += global_position.x
	rotated.z += global_position.z
	rotated.z += offset_z
	rotated.y -= leg_offset_y
	targ.global_position = rotated
