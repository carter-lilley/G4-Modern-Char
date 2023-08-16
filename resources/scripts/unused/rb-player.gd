extends rb_player_class
@export var pID: int

@export var natural_frequency: float = 5
@export var damping_coefficient: float = 5
@export var initial_response: float = 5

@export var jump: bool = false
@export var jump_strength: float = 5
@export var jump_max: float = 50

@export var turn_damp_fac: float = .12 #rate of exponential decay in dampening. higher values = faster dampening
@export var tilt_damp_fac: float = 1
@export var correct_damp_fac: float = 1

@export var spin_speed: float = 5

@onready var camera = $"../Camera3D"
#@onready var player_model = $guy_import

var currentDistance: float
var space_state 
var spring_col
var input_vec
var prev_velocity: Vector3 = Vector3.ZERO
var current_goal: Vector3
var ground_vel: Vector3

func _ready():
	space_state = get_world_3d().direct_space_state

func _process(delta):
	spring_col = _float_ray()
	input_vec = MultiplayerInput.get_stick(pID, "move_left", "move_right", "move_forward", "move_back")
	
func _integrate_forces(state):
	spin_speed += 1
	Globals.fire_ray_circle(space_state, self.position, 2, 0b00000000000000010101, spin_speed)
	rot_forces(state)
	if spring_col and !jump:
		_float_force(spring_col)
	if input_vec:
		_movement_force(input_vec, state)
	else:
		_movement_force(Vector2.ZERO, state)
	if MultiplayerInput.is_action_pressed(pID,"jump_button"):
		_jump(true)
	if MultiplayerInput.is_action_just_released(pID,"jump_button"):
		Globals.createTimer(.5, true, _jumpCancel, true)
#	detect_col(state)
#	clamp_rot(state)
	#exp(-tilt_damp * state.step)????????
	
func _float_ray():
	var _float_ray_col: Dictionary = Globals.fire_ray(space_state,self.position, Vector3(0,-1,0), ride_ray_length,0b00000000000000010101)
	if _float_ray_col:
		DrawLine3d.DrawCube(_float_ray_col.position, 0.1, Color(1, 0, 0))
		DrawLine3d.DrawLine(self.position,_float_ray_col.position,Color(0, 0, 1))
		return _float_ray_col
	else:
		return null

#---------------------------------------------------------------------------------------------------
func _jumpCancel():
	_jump(false)
	
func _jump(_bool: bool):
	jump = _bool
	if jump:
		var jump_force: Vector3 = Vector3.UP * jump_strength
		jump_force *= mass
		apply_central_force(jump_force)
	else:
		var return_force: Vector3 = Vector3.DOWN * -linear_velocity.y * -jump_strength/2
		return_force *= mass
		apply_central_force(return_force)
	
func _movement_force(_input : Vector2, state: PhysicsDirectBodyState3D):
	var _forward_ray_col: Dictionary = Globals.fire_ray(space_state,self.position, transform.basis.z, 1,0b00000000000000010101)
	var axis
	#remap joystick input from zero to max speewd
	var x_val = remap(_input.x, -1, 1, -speed, speed)
	var y_val = remap(_input.y, -1, 1, -speed, speed)
	var input_vec = Vector3(x_val,0,y_val)
	input_vec = input_vec.rotated(Vector3.UP, camera.rotation.y)
	var input_axis : Vector3 = input_vec.normalized()
	var input_mag : float = input_vec.length()
	
	if _forward_ray_col:
		DrawLine3d.DrawLine(self.position,self.position+transform.basis.z,Color(0, 0, 1))
		DrawLine3d.DrawCube(_forward_ray_col.position, 0.1, Color(1, 0, 0))
		var col_norm = _forward_ray_col.normal
		var sliding_axis = linear_velocity.normalized().cross(col_norm)
		var projection = col_norm * linear_velocity.dot(col_norm)
		var perpendicular_vector = sliding_axis - projection
		perpendicular_vector.y = 0
		perpendicular_vector = perpendicular_vector.normalized()
		print(perpendicular_vector)
		axis = col_norm
		DrawLine3d.DrawLine(_forward_ray_col.position,_forward_ray_col.position+col_norm,Color.DEEP_PINK)
		DrawLine3d.DrawLine(_forward_ray_col.position,_forward_ray_col.position+perpendicular_vector,Color.DEEP_PINK)
	else:
		axis = input_axis
		
	#check how far the distance between the goal and current facing direction are, 
	#and factor by 2 if far enough, makes for quicker turning
	var velDot : float = input_vec.normalized().dot(current_goal.normalized())
	var factor: float = dot_factor.sample(velDot)
	#-----------------------------------------------------------------------------
	
	var goal_vec = axis * input_mag
	current_goal = linear_velocity.move_toward(goal_vec, (acceleration*factor) * state.step) #goal velocity this step
	var neededAccel : Vector3 = (current_goal - linear_velocity) / state.step #the amount of acceleration needed to reach the "goal" velocity this step
	neededAccel = neededAccel.limit_length((max_accel*factor))
	neededAccel *= mass
	apply_central_force(Vector3(neededAccel.x,0,neededAccel.z))


func _float_force(_spring_col: Dictionary):
		var collider_vel: Vector3
		if _spring_col.collider is RigidBody3D:
			collider_vel = _spring_col.collider.linear_velocity
		else:
			collider_vel = Vector3.ZERO

		var down_force: float = Vector3.DOWN.dot(linear_velocity)
		var collider_dot = Vector3.DOWN.dot(collider_vel)
		var relVel = down_force - collider_dot

		var dist_to_Tar = self.position.distance_to(_spring_col.position) - ride_height

		var springForce = (dist_to_Tar * ride_strength) - (relVel * ride_damp)
		springForce*=mass
		apply_central_force(Vector3.DOWN * springForce)

func rot_forces(state: PhysicsDirectBodyState3D):
	
	ground_vel = Vector3(linear_velocity.x,0,linear_velocity.z)
	var ground_accel = (ground_vel - prev_velocity) / state.step
	
	var current_forward: Vector3 = transform.basis.z
	var current_up: Vector3 = transform.basis.y
	
	var tilt_axis = ground_accel.cross(Vector3.UP).normalized()
	
	var tilt_torque: Vector3
	if ground_accel.length() > tilt_threshold and tilt:
		var accel_magnitude = ground_accel.length()
		var tilt_angle_diff = current_up.signed_angle_to(ground_accel, tilt_axis)
		tilt_torque = (tilt_axis * (tilt_angle_diff*accel_magnitude)) * tilt_strength
		tilt_torque -= (angular_velocity * tilt_damp * exp(tilt_damp_fac * state.step))
		tilt_torque = tilt_torque.limit_length(tilt_force_limit)
		if tilt_DEBUG:
			DrawLine3d.DrawLine(self.position,self.position+tilt_axis,Color.GOLDENROD)
			DrawLine3d.DrawLine(self.position,self.position+tilt_torque,Color.DARK_GOLDENROD)
			DrawLine3d.DrawLine(self.position,self.position+ground_accel,Color.YELLOW)
	else:tilt_torque = Vector3.ZERO
#
#	var turn_torque: Vector3
#	if ground_vel.length() > velocity_threshold and turn:
#		var desired_forward: Vector3 = ground_vel.normalized()
#		var turn_angle_diff = current_forward.signed_angle_to(desired_forward, Vector3.UP)
#
#		var factor: float = dot_factor.sample(turn_angle_diff)
#		factor = remap(factor,2,1,1,2)
#
#		# Define system parameters
#		var f = natural_frequency # Natural frequency of the second-order system
#		var zeta = damping_coefficient  # Damping coefficient of the second-order system
#		var r = initial_response # Initial response of the second-order system
#
#		# Calculate system output
#		var time = state.step  # Time since the last frame update
#		var angular_error = turn_angle_diff / time  # Angular error rate
#
#		# Calculate second-order system response
#		var response = r * (1.0 - exp(-zeta * f * time) *
#									(cos(f * sqrt(1.0 - zeta * zeta * time * time)) +
#									(zeta * time * sin(f * sqrt(1.0 - zeta * zeta * time * time)))))
#
#		# Calculate torque to align with the system output
#		var desired_angular_velocity = Vector3.UP * (response - angular_error) * (turn_speed * factor)
#		turn_torque = (desired_angular_velocity - angular_velocity)
##		turn_torque -= (angular_velocity * turn_damp)
##		turn_torque = turn_torque.limit_length(turn_torque_limit)
#
#		if turn_DEBUG:
#			print(turn_torque)
#			DrawLine3d.DrawLine(self.position, self.position + (current_forward * ground_vel.length()), Color.RED)
#			DrawLine3d.DrawLine(self.position, self.position + (desired_forward * ground_vel.length()), Color.GREEN)
#			DrawLine3d.DrawLine(self.position, self.position + turn_torque, Color.DARK_GREEN)
#	else:turn_torque = Vector3.ZERO
#	apply_torque(turn_torque)
	
	var turn_torque: Vector3
	if ground_vel.length() > velocity_threshold and turn:
		var desired_forward: Vector3 = ground_vel.normalized()
		var turn_angle_diff = current_forward.signed_angle_to(desired_forward, Vector3.UP)
		#remap angle factor for faster turning on extreme angles (180, etc)
		var factor: float = dot_factor.sample(turn_angle_diff)
		factor = remap(factor,2,1,1,2)
		if abs(turn_angle_diff) > deg_to_rad(turn_threshold):
			var desired_angular_velocity = Vector3.UP * (turn_angle_diff / state.step) * (turn_speed * factor)

			var remaining_angle = abs(turn_angle_diff)
			var angle_ratio = remaining_angle / deg_to_rad(turn_threshold)
			var angle_factor = clamp(abs(1.0 - angle_ratio), 0, 1)

			turn_torque = (desired_angular_velocity - angular_velocity)
			turn_torque -= (angular_velocity * turn_damp * exp(turn_damp_fac * state.step))  # Apply exponential dampening
			turn_torque *= angle_factor
			turn_torque = turn_torque.limit_length(turn_torque_limit)
		if turn_DEBUG:
			DrawLine3d.DrawLine(self.position,self.position+(current_forward*ground_vel.length()),Color.RED)
			DrawLine3d.DrawLine(self.position,self.position+(desired_forward*ground_vel.length()),Color.GREEN)
			DrawLine3d.DrawLine(self.position,self.position+turn_torque,Color.DARK_GREEN)
	else: turn_torque = Vector3.ZERO
	
	var correction_torque: Vector3
	var current_angle: float = Globals.ShortestRot(Quaternion.from_euler(Vector3.UP),Quaternion.from_euler(current_up)).get_angle()
	if abs(current_angle) > deg_to_rad(correction_angle_limit) and correct:
		var _correction_axis = current_up.cross(Vector3.UP).normalized()
		var toGoal = Globals.ShortestRot(Quaternion.from_euler(Vector3.UP),Quaternion.from_euler(current_up))
		correction_torque = ((_correction_axis*(current_angle*correction_strength))-(angular_velocity*correction_damp))
		correction_torque.limit_length(correction_max)
		if correct_DEBUG:
			DrawLine3d.DrawLine(self.position,self.position+_correction_axis,Color.WHITE)
			DrawLine3d.DrawLine(self.position,self.position+correction_torque,Color.PURPLE)
	else: correction_torque = Vector3.ZERO
	
	var stopping_torque = -angular_velocity * stopping_torque_factor
	var sum_torque: Vector3 = tilt_torque+turn_torque+correction_torque+stopping_torque
	sum_torque *= mass
	apply_torque(sum_torque)
	
	prev_velocity = ground_vel

#func detect_col(state: PhysicsDirectBodyState3D) -> void:
#	var bodies = get_colliding_bodies()
#	for body in bodies:
#		if body.is_in_group("enviro"): #check colliding body is in the "players" group
#			var normal:Vector3 = (body.transform.origin - transform.origin).normalized()
#			var sliding_velocity = linear_velocity - normal * linear_velocity.dot(normal)
#			sliding_velocity.y = 0
#			DrawLine3d.DrawLine(self.position,self.position+sliding_velocity,Color.DEEP_PINK)
#			apply_central_force(sliding_velocity*3)
