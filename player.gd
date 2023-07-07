extends CharacterBody2D


const SPEED = 120.0
const JUMP_VELOCITY = 120.0
const DJUMP_VELOCITY = 170.0
const FALLING_GRAVITY = 600.0
const MAX_SLOPE_SPEED = 100.0
const SLOPE_ACC = 0.2
var GRAVITY = 400.0 # 1200

const PARALLEL_WIDTH = 100.0 # a little over 6 blocks
const MIN_PARALLEL_LENGTH = 8.0
const PARALLEL_SNAPS = 4
const PARALLEL_JUMP_VELOCITY = 150.0

const EX_COMPASS_REACH = 4.0
const COMPASS_JUMP_VELOCITY = 40.0
var compass_radius: float = 0.0
var compass_hit_pos = null

var walk_velocity = 0.0

var used_djump = false

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y -= JUMP_VELOCITY
	
	if Input.is_action_just_pressed("ui_accept") and !is_on_floor() and !used_djump:
		velocity.y /= 4
		velocity.y -= DJUMP_VELOCITY
		used_djump = true
	
	var movement_dir = get_movement_dir()
	if movement_dir.x:
		walk_velocity = movement_dir.x * SPEED
	else:
		walk_velocity = 0.0
		
	if is_on_floor():
		used_djump = false
	else:
		if velocity.y > 0.0:
			velocity.y += FALLING_GRAVITY * delta
		else:
			velocity.y += GRAVITY * delta

	var floor_query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2.DOWN * 100.0, 1);
	var floor_cast = get_world_2d().direct_space_state.intersect_ray(floor_query)
	if floor_cast.is_empty():
		$SpiderViewport/spider_model.dist_to_floor = INF
	else:
		$SpiderViewport/spider_model.dist_to_floor = floor_cast.position.distance_to(global_position)
	
	var indicators = {
		parallel = $/root/World/Indicators/Parallel,
		edge1 = $/root/World/Indicators/StraightEdge1,
		edge2 = $/root/World/Indicators/StraightEdge2,
		edgecol = $/root/World/Indicators/StraightEdgeCollider/LineCollider,
		compass = $/root/World/Indicators/Compass,
	}
	
	if Input.is_action_pressed("game_action_1") and get_action_dir().length() > -0.1:
		velocity = Vector2.ZERO
		var parallel_hit_data = parallel()
		
		if parallel_hit_data:
			indicators.parallel.l_points = [
				parallel_hit_data.lposition,
				parallel_hit_data.lposition3,
			]
			
			indicators.parallel.r_points = [
				parallel_hit_data.rposition,
				parallel_hit_data.rposition3,
			]
			
			indicators.parallel.refresh = true
			indicators.parallel.visible = true
			indicators.parallel.player_position = global_position
		else:
			indicators.parallel.visible = false
	else:
		indicators.parallel.visible = false
	
	if Input.is_action_just_released("game_action_1"):
		var parallel_hit_data = parallel()
		
		if parallel_hit_data:
			self.position = parallel_hit_data.position
			self.velocity = Vector2.UP * PARALLEL_JUMP_VELOCITY
			used_djump = false

	if Input.is_action_pressed("game_action_2"):
		var straight_edge_data = straight_edge()
		
		if straight_edge_data and straight_edge_data.pos1:
			indicators.edge1.points = [global_position, straight_edge_data.pos1]
			
			if straight_edge_data.pos2:
				var segment = SegmentShape2D.new()
				segment.a = straight_edge_data.pos1
				segment.b = straight_edge_data.pos2
				indicators.edgecol.shape = segment
				indicators.edge2.points = [straight_edge_data.pos1, straight_edge_data.pos2]
				indicators.edge2.visible = true
			else:
				indicators.edge2.visible = false
			
			
	if Input.is_action_just_pressed("game_action_3"):
		var radius = compass_start()
		
		if radius:
			indicators.compass.compass_position = global_position
			indicators.compass.compass_scale = radius

			compass_radius = radius
		
		velocity = Vector2.ZERO
		indicators.compass.visible = true
	elif Input.is_action_pressed("game_action_3"):
		var point = compass_point(compass_radius)

		if point:
			indicators.compass.end_position = point

			compass_hit_pos = point
		
		velocity = Vector2.ZERO		
	elif Input.is_action_just_released("game_action_3"):
		if compass_hit_pos:
			position = compass_hit_pos
			velocity = Vector2.UP * COMPASS_JUMP_VELOCITY

		compass_hit_pos = null
		indicators.compass.end_position = null
		indicators.compass.visible = false	

	velocity.x = walk_velocity

	move_and_slide()
	
	var spider_model = $SpiderViewport/spider_model
	spider_model.target_x = -position.x / 40.0
	spider_model.x_velocity = velocity.x
	spider_model.y_velocity = velocity.y
	spider_model.is_on_floor = is_on_floor()
	
func parallel():
	var action_dir = action_dir_snapped()
	
	var checkpos = global_transform.origin + action_dir
	
	var left = action_dir.rotated(-PI/2)
	var right = action_dir.rotated(PI/2)
	
	var space = get_world_2d().direct_space_state
	
	var first_hit_data = null
	var hit_data = null
	
	for n in 1200:
		var l_raycast = PhysicsRayQueryParameters2D.create(checkpos, checkpos + left * PARALLEL_WIDTH, 2)
		var l_intersec = space.intersect_ray(l_raycast)
		var r_raycast = PhysicsRayQueryParameters2D.create(checkpos, checkpos + right * PARALLEL_WIDTH, 2)
		var r_intersec = space.intersect_ray(r_raycast)
		
		if hit_data:
			checkpos += hit_data.direction
		else:
			checkpos += action_dir
		
		var checkpos_point = PhysicsPointQueryParameters2D.new()
		checkpos_point.position = checkpos
		checkpos_point.collision_mask = 2
		if space.intersect_point(checkpos_point):
			# checkpoint is inside a block
			if hit_data:
				# parallel lines have led to a dead end, we're done
				break
			
			var new_point_raycast = PhysicsRayQueryParameters2D.create(
				checkpos - action_dir * 0.01, 
				checkpos
			);
			
			var new_point = space.intersect_ray(new_point_raycast)
			
			if new_point.is_empty():
				break
			
			checkpos = new_point.position
			action_dir = action_dir.reflect(new_point.normal)
			left = action_dir.rotated(-PI/2)
			right = action_dir.rotated(PI/2)
			break
			
		if (l_intersec.is_empty() or 
			r_intersec.is_empty()):
			if hit_data:
				break
			continue
		
		if (l_intersec.normal.rotated(PI).angle_to(r_intersec.normal) < 0.05 and
			l_intersec.normal.rotated(-PI / 2).angle_to(action_dir) < 0.15):
			if (l_intersec.position.distance_to(r_intersec.position) > PARALLEL_WIDTH):
				if hit_data:
					break
				continue
			
			var op_predic_l = l_intersec.position + l_intersec.normal * (l_intersec.position.distance_to(r_intersec.position) + 0.5)
			var op_predic_r = r_intersec.position + r_intersec.normal * (r_intersec.position.distance_to(l_intersec.position) + 0.5)
			var op_ray_l = PhysicsRayQueryParameters2D.create(l_intersec.position + l_intersec.normal * 0.1, op_predic_l)
			var op_ray_r = PhysicsRayQueryParameters2D.create(r_intersec.position + r_intersec.normal * 0.1, op_predic_r)
			var op_hit_l = space.intersect_ray(op_ray_l)
			var op_hit_r = space.intersect_ray(op_ray_r)
			
			if (op_hit_l.is_empty() or op_hit_r.is_empty()):
				if hit_data:
					break
				continue
				
			if (op_hit_r.position.distance_to(l_intersec.position) > 16.0 or
				op_hit_l.position.distance_to(r_intersec.position) > 16.0 or
				op_hit_r.normal.distance_to(l_intersec.normal) > 3.2 or
				op_hit_l.normal.distance_to(r_intersec.normal) > 2.3):
				if hit_data:
					break
				continue
			
			if first_hit_data and abs(
				l_intersec.position.distance_to(r_intersec.position) -
				first_hit_data.lposition.distance_to(first_hit_data.rposition)
				) > 1.6:
				if hit_data:
					break
				continue
			
			hit_data = {
				position = (l_intersec.position + r_intersec.position) / 2,
				lposition = l_intersec.position,
				rposition = r_intersec.position,
				lposition2 = op_hit_r.position,
				rposition2 = op_hit_l.position,
				direction = l_intersec.normal.rotated(- PI / 2),
			}
			
			if first_hit_data == null:
				checkpos = (l_intersec.position + op_hit_l.position) / 2
				
				action_dir = (
						l_intersec.normal.rotated(- PI / 2) +
						r_intersec.normal.rotated(PI / 2)
					).normalized()
				
				left = action_dir.rotated(-PI/2)
				right = action_dir.rotated(PI/2)
				first_hit_data = hit_data
		else:
			if hit_data:
				break
	
	if first_hit_data and hit_data and hit_data.lposition.distance_to(first_hit_data.lposition) > MIN_PARALLEL_LENGTH:
		return {
			position = hit_data.position,
			lposition = hit_data.lposition,
			rposition = hit_data.rposition,
			lposition2 = hit_data.lposition2,
			rposition2 = hit_data.rposition2,
			lposition3 = first_hit_data.lposition,
			rposition3 = first_hit_data.rposition,
			lposition4 = first_hit_data.lposition2,
			rposition4 = first_hit_data.rposition2,
			direction = hit_data.direction,
		}
	else:
		return null
		
func straight_edge():
	var space = get_world_2d().direct_space_state
	
	var cast_dir = action_dir_snapped()
	var raycast = PhysicsRayQueryParameters2D.create(position + cast_dir * 1.0, position + cast_dir * 400, 4)
	var hit_data = space.intersect_ray(raycast)
	
	if hit_data.is_empty():
		return null

	cast_dir = cast_dir.reflect(hit_data.normal.rotated(PI / 2))	
	
	raycast = PhysicsRayQueryParameters2D.create(hit_data.position + cast_dir * 1.0, hit_data.position + cast_dir * 400, 4)
	var hit_data2 = space.intersect_ray(raycast)
		
	if hit_data2.is_empty():
		return {
			pos1 = hit_data.position,
			pos2 = null,
		}
		
	return {
		pos1 = hit_data.position,
		pos2 = hit_data2.position,
	}
	
func compass_start():
	var space = get_world_2d().direct_space_state	

	var circle_size = 1

	for n in 100:
		var shape = CircleShape2D.new()
		shape.radius = circle_size

		var query = PhysicsShapeQueryParameters2D.new()
		query.transform = transform
		query.shape = shape
		query.collision_mask = 8

		var intersects = space.intersect_shape(query)

		if intersects.size() > 0:
			return circle_size

		circle_size += 1

func compass_point(radius):
	var cast_dir = get_action_dir()
	var reach = cast_dir * (radius + EX_COMPASS_REACH)
	var raycast = PhysicsRayQueryParameters2D.create(position, position + reach, 8)
	var hit = get_world_2d().direct_space_state.intersect_ray(raycast)

	if hit.is_empty():
		return null
	else:
		return hit.position

func sort_ray_hit(a, b):
	return a.distance_to(position) < b.distance_to(position)

func get_movement_dir():
	if Input.is_action_pressed("game_action_1") or Input.is_action_pressed("game_action_2"):
		return Vector2.ZERO
			
	var WASDdir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if WASDdir.length() > 0.05:
		return WASDdir.normalized()
	else:
		return Vector2.ZERO
	
var cached_action_dir = Vector2.RIGHT

func get_action_dir():	
	var WASDdir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if WASDdir.length() > 0.05:
		cached_action_dir = WASDdir
		return WASDdir.normalized()
	else:
		return cached_action_dir
		
func action_dir_snapped():
	var action_dir = get_action_dir()
	var action_dir_angle = action_dir.angle()
	action_dir_angle = floor((action_dir_angle / PI * PARALLEL_SNAPS) + 0.5) / PARALLEL_SNAPS * PI
	return Vector2.RIGHT.rotated(action_dir_angle)
