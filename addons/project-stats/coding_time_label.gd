tool
extends Label

const api = preload("api.tres")



func init():
	update_control()
	api.connect("coding_time_changed", self, "update_control")
	api.connect("show_coding_time_setting_changed", self, "on_show_coding_time_setting_changed")

func update_control():
	var time = api.get_coding_time_readable()
	text = time

func on_show_coding_time_setting_changed(is_visible:bool):
	visible = is_visible
