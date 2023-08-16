extends orbit_cam_class

var cam_rot : Vector3 #pitch, yaw, & roll respectively
var full_rotations
var input_raw
var input_adj
var prev_origin : Vector3

func _ready():
	prev_origin = cam_tar.transform.origin + arm_origin
	if arm_vector == Vector3.ZERO:
		arm_vector = self.transform.origin - cam_tar.transform.origin - arm_origin
	if look_offset == Vector3.ZERO:
		look_offset = Vector3(0,0,100)
	pitch_limit.x = deg_to_rad(pitch_limit.x)
	pitch_limit.y = deg_to_rad(pitch_limit.y)

func _process(_delta) -> void:
	input_raw = MultiplayerInput.get_stick(0, "cam_left", "cam_right", "cam_up", "cam_down")
	input_adj = MultiplayerInput.response_curve(input_raw,stick_response)
	#remap pitch on curve to determine how close in the camera should pull
	#for when tilting towards the ground
	var mapped_pitch = remap(cam_rot.x,pitch_limit.y,pitch_limit.x,0,1)
	var mapped_arm_origin = arm_height_curve.sample(mapped_pitch)
	var mapped_arm_length = arm_length_curve.sample(mapped_pitch)
	arm_origin.y = mapped_arm_origin
	arm_vector.z = mapped_arm_length
	#normalize the rotations around the yaw from -180-180 + full rotations
	cam_rot.y = normalize_rad_rot(cam_rot.y)

func _physics_process(delta):
	if input_adj:
		spin_cam(input_adj)
	#set timer when no input
	if cam_tar.is_class("CharacterBody3D") and !input_adj:
		var char_ground_vel : Vector3 = Vector3(cam_tar.velocity.x,cam_tar.velocity.y,cam_tar.velocity.z)
		correct_cam(cam_tar.facing_dir, delta)
	positionCamera(delta)

func positionCamera(delta):
	# Calculate the new current origin
	var curr_origin = cam_tar.transform.origin + arm_origin
	# Lerp towards the new current origin
#	var lerped_origin = prev_origin.lerp(curr_origin, follow_smooth * delta)
	var lerped_origin = prev_origin.lerp(curr_origin, 1.0 - pow(follow_damp, follow_smooth * delta))
	# Update the previous origin for the next frame
	prev_origin = lerped_origin
	#place the camera at the pole origin
	self.transform.origin = lerped_origin
#	#calculate current camera pitch axis based on previous yaw(rotate the right vector by the cameras yaw)
	var up_down_axis = Vector3.RIGHT.rotated(Vector3.UP,cam_rot.y)
#	#Apply yaw first
	var Δ_offset = arm_vector.rotated(Vector3.UP,cam_rot.y)
	var Δ_look = look_offset.rotated(Vector3.UP,cam_rot.y)
##	#Apply pitch
	Δ_offset = Δ_offset.rotated(up_down_axis,cam_rot.x)
	Δ_look = Δ_look.rotated(up_down_axis,cam_rot.x)
#	#Once angle of camera is calculated based on offsets, pull the camera back along its pole offset
#	Calculate where it wants to be and where it is and slowly move it towards that point, for a smooth transition
	self.transform.origin += Δ_offset
	look_at(lerped_origin + Δ_look,Vector3.UP)
	
func spin_cam(_input: Vector2):
	#remap to accnt for joystick input
	var x_val = remap(_input.x, 1, -1, -Hsense, Hsense)
	var y_val = remap(_input.y, -1, 1, -Vsense, Vsense)
	var mapped_vec = Vector2(x_val,y_val)
	
	cam_rot.y += mapped_vec.x
	cam_rot.x += mapped_vec.y
	cam_rot.x = clamp(cam_rot.x, pitch_limit.x, pitch_limit.y)

func correct_cam(tar_facing_dir: Vector3, delta):
	var target_angle = rad_to_deg(tar_facing_dir.y)
	var current_angle = rad_to_deg(cam_rot.y)
	var angle_difference = target_angle - current_angle

	if angle_difference > 180:
		angle_difference -= 360
	elif angle_difference < -180:
		angle_difference += 360
	cam_rot.x = lerp(cam_rot.x, deg_to_rad(20), delta * correct_speed)
	cam_rot.y = lerp(cam_rot.y, cam_rot.y + deg_to_rad(angle_difference), delta * correct_speed)
	print(cam_rot)
	
func normalize_rad_rot(yaw_radians: float) -> float:
	# Ensure yaw is within the range -pi to pi radians
	while yaw_radians < -PI:
		yaw_radians += 2.0 * PI
	while yaw_radians > PI:
		yaw_radians -= 2.0 * PI

	# Calculate the number of full rotations
	full_rotations = int(yaw_radians / (2.0 * PI))

	# Calculate the yaw within the range -pi to pi radians
	var normalized_yaw_radians = yaw_radians - (full_rotations * 2.0 * PI)
	if normalized_yaw_radians > PI:
		normalized_yaw_radians -= 2.0 * PI

	return (normalized_yaw_radians)

#
#    return (normalized_yaw, rotations)
##func collide():
##	var space_state = get_world_3d().direct_space_state
##	var from = cam_target.transform.origin + _camera_data.pole_origin
##	var to = self.transform.origin
##	var ray: Dictionary = _globals.fireray(space_state,from,to,0b00000000000000010101)
##	if ray.is_empty() == false:
##		self.transform.origin = ray.position
############~~~~~~~~~~UTILS~~~~~~~~~############
##
##func tween_offset(new_target:Vector3):
##	var target_tween = create_tween()
##	target_tween.tween_property(_camera_data,"target_offset",new_target,.1)
##	target_tween.set_trans(Tween.TRANS_QUINT)
##	target_tween.set_ease(Tween.EASE_OUT)
