extends Node3D

@export var collisionShapePath: NodePath

var collisionShape: CollisionShape3D

func _ready():
	collisionShape = get_node(collisionShapePath)
	if not collisionShape:
		print("Collision shape not found!")
		return
	
	var halfHeight = 0.0
	if collisionShape.shape is CapsuleShape3D:
		halfHeight = collisionShape.shape.height * 0.5
	else:
		halfHeight = collisionShape.shape.extents.y * 0.5
	
	var newPosition = transform.origin
	newPosition.y -= halfHeight
	transform.origin = newPosition
