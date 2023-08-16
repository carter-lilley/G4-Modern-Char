extends Node

#TWEEN UTILS-------------------------------------------------------

#func stween_cont(node: Node, property: String, target: Variant, _trans: Tween.TransitionType, _ease: Tween.EaseType):
#	var tween = node.create_tween()
#	var current_value = node.get(property)
#	var diff = variant_diff(current_value,target)
#	var duration = abs(diff)
#	tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease)

func stween_to(node: Node, property: String, target: Variant, duration: float, _trans: Tween.TransitionType, _ease: Tween.EaseType, relative: bool, parallel: bool):
	var tween = node.create_tween()
	tween.set_parallel(parallel)
#	print("call")
	if relative:
#		print("relative")
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease).as_relative()
	else:
#		print("not relative")
		tween.tween_property(node, property, target, duration).set_trans(_trans).set_ease(_ease)



#RAY UTILS-------------------------------------------------------
func fire_ray_circle(space_state: Object, from: Vector3, radius: float, mask_bit: int,  step: float) -> Array:
	var rays = []
	for i in range(8):
		var angle = deg_to_rad(i * 45) + deg_to_rad(step)  # Angle in radians, spaced evenly at 45 degrees
		var dir = Vector3(cos(angle), sin(angle), 0)  # Direction vector on the Z/Y plane
		var to = from + dir * radius
		var query = PhysicsRayQueryParameters3D.create(from, to, mask_bit)
		var col = space_state.intersect_ray(query)
		DrawLine3d.DrawLine(from,to,Color(0, 1, 1))
		rays.append(col)
	return rays

func fire_ray(space_state : Object,from : Vector3, dir : Vector3,length: float,mask_bit : int) -> Dictionary:
	var to = (from + (dir.normalized() * length))
	var query = PhysicsRayQueryParameters3D.create(from, to, mask_bit)
	var col = space_state.intersect_ray(query)
	if col:
		return col
	return {}


#MATH UTILS-------------------------------------------------------
func get_child_by_type(node: Node, type_name: String) -> Node:
	for child in node.get_children():
		if child.is_class(type_name):
			return child
	return null

func ShortestRot(q1:Quaternion,q2:Quaternion) -> Quaternion:
	if q1.dot(q2) < 0:
		return q1 * QuatMultiply(q2,-1).inverse()
	else: return q1*q2.inverse()

func QuatMultiply(input:Quaternion,scalar:float) -> Quaternion:
	return Quaternion(input.x * scalar, input.y * scalar, input.z * scalar, input.w * scalar);

func variant_diff(initial_value: Variant, target_value: Variant) -> float:
	var result: float = 0.0

	match typeof(initial_value):
		TYPE_FLOAT:
			result = (target_value - initial_value)
		TYPE_VECTOR3:
			result = (target_value - initial_value).length()
		# Add more cases for other variant types as needed
	return result


#TIMER UTILS-------------------------------------------------------
func createTimer(wait_time: float, one_shot: bool, method: Callable, start: bool = false) -> Timer:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	timer.connect("timeout", method)
	
	if start:
		add_child(timer)
		timer.start()

	return timer
	
func formatTime(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var remainingSeconds = int(seconds) % 60
	return pad_zero(minutes) + ":" + pad_zero(remainingSeconds)

func pad_zero(number: int) -> String:
	var strNumber = str(number)
	if number < 10:
		strNumber = "0" + strNumber
	return strNumber

#SPRITE UTILS-------------------------------------------------------
func random_tint(_sprite: Sprite2D):
	var red = randf_range(0, 1)
	var green = randf_range(0, 1)
	var blue = randf_range(0, 1)
	# Set the random color as the sprite's modulate color
	_sprite.modulate = Color(red, green, blue)
	return
