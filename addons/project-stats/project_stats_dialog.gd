tool
extends AcceptDialog

const api = preload("api.tres")

func init():
	$"VBoxContainer/TabContainer/Main".init()
	$"VBoxContainer/TabContainer/UpdateSettings".init()

	$VBoxContainer/HBoxContainer/ShowCodingTime.pressed = api.get_editor_setting("show_coding_time_in_output")

	$"VBoxContainer/HBoxContainer/ColorPickerPanel".color = api.get_editor_setting("output_panel_first_color")
	$"VBoxContainer/HBoxContainer/ColorPickerPanel2".color = api.get_editor_setting("output_panel_second_color")

func _on_ShowUpdateModes_toggled(button_pressed):
	api.emit_signal("show_coding_time_setting_changed", button_pressed)
	api.set_editor_setting("show_coding_time_in_output", button_pressed)


func _on_TabContainer_tab_changed(tab):
	pass # Replace with function body.



func _on_ColorPickerPanel2_color_changed(color):
	api.emit_signal("output_panel_color_changed")
	api.set_editor_setting("output_panel_second_color", color)


func _on_ColorPickerPanel_color_changed(color):
	api.emit_signal("output_panel_color_changed")
	api.set_editor_setting("output_panel_first_color", color)
