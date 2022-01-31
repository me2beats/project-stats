tool
extends EditorPlugin

const Utils = preload("utils.tres")
const Api = preload("api.tres")

#var stats_control: = preload("stats_control.tscn").instance()

var output_panel_stats = preload("output_panel_stats.tscn").instance()

var project_info_dialog = preload("project_info_dialog.tscn").instance()


func _enter_tree():
	var base_color = get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color")

	Api.init(self)

#	stats_control.get_node("ColorRect").color = base_color
	var base = get_editor_interface().get_base_control()
	
	var output_panel:HBoxContainer =  Utils.get_log(base).get_child(0)
	output_panel.add_child(output_panel_stats)
	output_panel.move_child(output_panel_stats, 1)
	
	output_panel_stats.init()
	
	base.add_child(project_info_dialog)
	add_tool_menu_item("Project Stats", self, "on_project_stats_tool_pressed")

	var parent:VBoxContainer = Utils.find_node_by_class_path(base, ['VBoxContainer'])


	yield(get_tree(), "idle_frame")
	if !is_enabled:
		Api.increment_setting("opened_times")



func on_project_stats_tool_pressed(__):
	project_info_dialog.init()
	project_info_dialog.popup_centered()






# favorite key later

func _input(event):
	event = event as InputEventKey
	if not event: return
	
	if Input.is_key_pressed(KEY_F1) and event.pressed and not event.echo:
		Api.f1_pressed_count = Api.increment_setting("f1_pressed")

	elif Input.is_key_pressed(KEY_S) and event.pressed and not event.echo and event.control:

		Api.ctrl_s_pressed_count = Api.increment_setting("ctrl_s_pressed")


	

func on_code_timeout():
	return

func _exit_tree():
	if not is_disabled:
		Api.increment_setting("closed_times")
	
	if output_panel_stats:
		output_panel_stats.queue_free()
	
#	stats_control.queue_free()
	if Api.coding_timer:
		Api.coding_timer.queue_free()

	if project_info_dialog:
		project_info_dialog.queue_free()

	remove_tool_menu_item("Project Stats")

	Api.quit()



var is_disabled = false
func disable_plugin():
	is_disabled = true



var is_enabled = false
func enable_plugin():
	is_enabled = true
		
