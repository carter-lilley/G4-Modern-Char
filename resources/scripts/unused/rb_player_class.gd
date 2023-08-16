extends RigidBody3D
class_name rb_player_class

@export var dot_factor: Curve

@export_category("Tilt")
@export var tilt: bool = true
@export var tilt_DEBUG: bool = true
@export var tilt_strength: float = 1.5
@export var tilt_damp: float = .8
@export var tilt_threshold: float = .5
@export var tilt_force_limit: float = 1

@export_category("Correction")
@export var correct: bool = true
@export var correct_DEBUG: bool = true
@export var correction_angle_limit: float = 10
@export var correction_strength: float = .1
@export var correction_damp: float = .02
@export var correction_max: float = 100

@export_category("Turning")
@export var turn: bool = true
@export var turn_DEBUG: bool = true
@export var turn_speed: float = .1  # Adjust the desired turn speed as needed
@export var turn_damp: float = 0.02  # Adjust the base proportional gain as needed
@export var turn_torque_limit: float = 100
@export var velocity_threshold: float = 0.05  # Adjust the threshold as needed
@export var turn_threshold: float = 5.5  # Adjust the angle threshold as needed

@export var stopping_torque_factor: float = 45 #Higher values will result in stronger stopping torque

@export_category("Ride")
@export var ride_ray_length: float = 3
@export var ride_height: float = 1.3
@export var ride_strength: float = 1200
@export var ride_damp: float = 35

@export_category("Movement")
@export var speed: float = 8 #run speed
@export var acceleration: float = 1000 #how fast the character can reach max speed
@export var max_accel: float = 1000 #limit max force that can be applied when accelerating

