extends Node

func _ready():
	set_split_offset(get_tree().get_root())

func set_split_offset(node):
	if node is HSplitContainer:
		node.split_offset = self.size.x / 2
	
	for child in node.get_children():
		set_split_offset(child)
