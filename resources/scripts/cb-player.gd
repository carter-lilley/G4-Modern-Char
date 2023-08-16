extends cb_player_class
@export var pID: int
@onready var cam: Node = $"../Camera3D"
@onready var model: Node = $guy_import
@export var collision_impulse: float = 1.0

@export var ACCEL: float = 10.0
@export var MAX_SPEED: float = 5.0

const JUMP_VELOCITY = 4.5
var facing_dir: Vector3 = Vector3.ZERO
var input_raw
#NOTE TO SELF - SEPERATE STOPPING & STARTING ACCEL

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _process(delta):
	input_raw = MultiplayerInput.get_stick(pID, "move_left", "move_right", "move_forward", "move_back")
	
func _physics_process(delta):
	var ground_vel: Vector3 = Vector3(velocity.x,0,velocity.z)
	var ground_accel: Vector3 = ground_vel - prev_vel
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if MultiplayerInput.is_action_pressed(pID,"jump_button") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if input_raw:
		print(input_raw)
		move(delta)

	rot_turn(ground_vel, delta)
	rot_tilt(ground_accel, delta)
	check_and_apply_force()
	prev_vel = ground_vel

func rot_tilt(_ground_accel: Vector3, delta: float):
	var tilt_axis = _ground_accel.cross(Vector3.UP).normalized()
	var current_up: Vector3 = transform.basis.y
	var accel_magnitude = _ground_accel.length()
	var tilt_angle_diff = current_up.signed_angle_to(_ground_accel, tilt_axis)
	if tilt_DEBUG:
		DrawLine3d.DrawLine(self.position,self.position+tilt_axis,Color.GOLDENROD)
		DrawLine3d.DrawLine(self.position,self.position+_ground_accel,Color.YELLOW)
			
func rot_turn(_ground_vel: Vector3, delta: float):
	var current_forward: Vector3 = model.transform.basis.z
	var desired_forward: Vector3 = _ground_vel.normalized()
	var turn_angle_diff = current_forward.signed_angle_to(desired_forward, Vector3.UP)
	
	#remap angle factor for faster turning on extreme angles (180, etc)
	var factor: float = dot_factor.sample(turn_angle_diff)
	factor = remap(factor,2,1,1,2)
	
	var target_rotation = model.transform.basis.get_euler()
	target_rotation.y += turn_angle_diff
	var rotation_speed = 5.0 * factor  # Adjust this value to control the rotation speed
	facing_dir = lerp(model.transform.basis.get_euler(), target_rotation, rotation_speed * delta)
	model.transform.basis = Basis(Vector3(0, 1, 0), facing_dir.y)
	
	if turn_DEBUG:
		DrawLine3d.DrawLine(self.position,self.position+(current_forward*_ground_vel.length()),Color.RED)
		DrawLine3d.DrawLine(self.position,self.position+(desired_forward*_ground_vel.length()),Color.GREEN)

func move(delta: float):
# Get the input direction and handle the movement/deceleration.
	var input_dir = input_raw.normalized()
	var input_mag = input_dir.length()
	var move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	move_dir = move_dir.rotated(Vector3.UP, cam.rotation.y)
			
	if move_dir:
		var max_vel: Vector2 = Vector2(move_dir.x * (input_mag*MAX_SPEED),move_dir.z * (input_mag*MAX_SPEED)) #X & Z in V2...NOT XYZ
		velocity.x = move_toward(velocity.x, max_vel.x, ACCEL)
		velocity.z = move_toward(velocity.z, max_vel.y, ACCEL)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCEL)
		velocity.z = move_toward(velocity.z, 0, ACCEL)
#	Variant interpolate_value ( Variant initial_value, Variant delta_value, float elapsed_time, float duration, TransitionType trans_type, EaseType ease_type ) static
	move_and_slide()

func check_and_apply_force() -> void:
	var collision_count = get_slide_collision_count()
	if collision_count > 0:
		var collision = get_slide_collision(0)
		if collision:
			var collided_body = collision.get_collider()
			if collided_body is RigidBody3D:
				var collision_point = collision.get_position()
				var force_direction = -collision.get_normal().normalized()
				var force_magnitude = MAX_SPEED * collision_impulse

				# Smooth the force application over time
				var smoothing_factor = 0.8

				# Calculate the baseline push amount based on the input direction
				var baseline_push_amount = 1.0
				if velocity.dot(force_direction) <= 0:
					baseline_push_amount = 0.2

				var smoothed_force = force_direction * force_magnitude + force_direction * baseline_push_amount
				var current_velocity = collided_body.linear_velocity
				var target_velocity = smoothed_force * smoothing_factor
				var interpolated_velocity = current_velocity.move_toward(target_velocity, smoothing_factor)
				collided_body.linear_velocity = interpolated_velocity

