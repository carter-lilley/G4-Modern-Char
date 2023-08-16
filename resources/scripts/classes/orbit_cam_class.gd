extends Camera3D
class_name orbit_cam_class

@export var cam_tar: Node

@export var Hsense:=0.045
@export var Vsense:=0.025

@export var follow_smooth:=8
@export var follow_damp:= 0.2

@export var stick_response: Curve

@export var arm_height_curve: Curve #0.6-1.0
@export var arm_length_curve: Curve #-2.5-1.7

@export var pitch_limit : Vector2 = Vector2(-45,60) #stops "tumbling" effect at poles

@export var arm_vector : Vector3 = Vector3(0,0,-2.5) # length & dir of pole
@export var arm_origin : Vector3 = Vector3(0,0.6,0) # move pole origin 
@export var look_offset : Vector3 = Vector3(0,0,0) # look position offset (relative to origin & target node)

@export var correct_speed: float = 0.01
