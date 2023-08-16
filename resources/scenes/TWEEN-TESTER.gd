extends MeshInstance3D
@onready var char: Node = $"../Character"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	Globals.stween_to(self,"position",char.position,1,Tween.TRANS_LINEAR,Tween.EASE_IN, false, true)
#	if MultiplayerInput.is_action_just_pressed(0,"jump_button"):
#		Globals.stween_to(self,"position",char.position,1,Tween.TRANS_LINEAR,Tween.EASE_IN, false, true)
