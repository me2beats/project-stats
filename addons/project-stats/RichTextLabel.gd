tool
extends RichTextLabel

"""
do this later, after jam
"""


var api = preload("api.tres")
var utils = preload("utils.tres")


func init():
	rect_min_size = Vector2(100,0)
	update_control()
	api.connect("coding_time_changed", self, "update_control")
	api.connect("show_coding_time_setting_changed", self, "on_show_coding_time_setting_changed")
	api.connect("output_panel_color_changed", self, "update_control")

# pls don't look here
func update_control():
	var arr = utils.seconds_to_hms_array(api.get_coding_time())
#	var col = '#ffeca1' 
#	var col = api.get_editor_setting("output_panel_first_color")
	var col = "#"+(api.get_editor_setting("output_panel_first_color") as Color).to_html(true)
#	var col1 = '#6a6d83'
	var col1 = "#"+(api.get_editor_setting("output_panel_second_color") as Color).to_html(true)

	Color(0.415686, 0.427451, 0.513726)
	bbcode_text = "[color=%s]%s[/color][color=%s]h:[/color][color=%s]%s[/color][color=%s]m:[/color][color=%s]%s[/color][color=%s]s[/color]" % [col, arr[0], col1,  col, arr[1], col1, col, arr[2], col1]
	hint_tooltip = "Coding Time "+api.get_coding_time_readable()

func on_show_coding_time_setting_changed(is_visible:bool):
	visible = is_visible
