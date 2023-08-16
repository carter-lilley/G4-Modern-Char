extends CharacterBody3D
class_name cb_player_class

var prev_vel: Vector3

@export var dot_factor: Curve

@export_category("Tilt")
@export var tilt_DEBUG: bool = true
@export var tilt_strength: float = 1.5
@export var tilt_damp: float = .8

@export_category("Turning")
@export var turn: bool = true
@export var turn_DEBUG: bool = true
@export var turn_speed: float = .1  # Adjust the desired turn speed as needed
@export var turn_damp: float = 0.02  # Adjust the base proportional gain as needed

@export var stopping_torque_factor: float = 45 #Higher values will result in stronger stopping torque
