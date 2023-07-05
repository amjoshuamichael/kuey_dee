extends Camera2D


func _ready():
	pass

const CAM_SPEED: float = 0.2
const TRACK_PLAYER: float = 0.1
var track_player_offset = Vector2.ZERO

func _init():
	#RenderingServer.frame_pre_draw.connect(move_to_player)
	pass
	
func _physics_process(delta):
	var player_pos = $/root/World/Player.global_position
	var player_vel = $/root/World/Player.velocity * TRACK_PLAYER
	track_player_offset = lerp(track_player_offset, player_vel, CAM_SPEED)
	global_position = player_pos - track_player_offset
	pass
