#extends Node
##
##var input_dat := {
##	"device": null,
##	"move_vector": Vector2.ZERO
##}
##
#func _ready():
#	set_process_input(true)
##
##func _input(event):
##	if event.type == InputEvent.JOYSTICK_MOTION:
##        # Get the vector of the joystick input
##		var movement_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
##        # Store the joystick input vector in the dictionary with the device name
##		input_dat["device"] = event.device
##
#func _process(delta):
#	MultiplayerInput.is_action_pressed(0, "jump")
#    # Get the vector of the joystick input
##	var movement_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
##	input_dat["device"] = event.device
