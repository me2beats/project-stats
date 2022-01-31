tool
extends HBoxContainer


func init():
	for child in get_children():
		child = child as Control
		if child.has_method("init") and child.visible:
			child.init()
