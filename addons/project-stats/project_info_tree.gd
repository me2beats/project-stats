tool
extends Tree

const Api = preload("api.tres")


var modes:Dictionary

enum UpdateModes {
	UPDATE_ON_POPUP = 1,
	UPDATE_ASAP = 2,
	UPDATE_NEVER = 4
}

var should_update = false

const parents = ["scripts", "scenes", "various"]

const type1 = UpdateModes.UPDATE_ON_POPUP+UpdateModes.UPDATE_NEVER
const type2 = UpdateModes.UPDATE_ON_POPUP+UpdateModes.UPDATE_ASAP


#the second arg (String) is - if the item is a child or a parent itself (empty line)
const Data  = {
	"scripts" : [type1, "scripts", "get_script_count"],
	"non_plugin_scripts" : [type1, "scripts", "get_non_plugin_script_count"],
	"scenes" : [type1, "scenes", "get_scene_count"],
	"non_plugin_scenes" : [type1, "scenes", "get_non_plugin_scene_count"],
	"max_nodes" : [type1, "scenes", "get_max_nodes_in_a_scene"],
	"max_nodes_non_plugin" : [type1, "scenes", "get_max_nodes_in_non_plugin_scene"],
	"lines_total" : [type1, "scripts", "get_scripts_total_lines_count"],
	"lines_total_non_plugin" : [type1, "scripts", "get_non_plugin_scripts_total_lines_count"],
	"coding_time" : [type2, "scripts", "get_coding_time_readable"],
	"crashes" : [type2, "various", "get_crash_count"],
	"project_opened_times" : [type2, "various", "project_opened_times"],
	"editor_nodes_count" : [type1, "various", "get_editor_nodes_count"],
	"f1_pressed_count" : [type2, "various", "f1_pressed"],
	"ctrl_s_pressed_count" : [type2, "various", "ctrl_s_pressed"]
	
}

var default_modes = {}

var dropdown:PopupMenu

var is_main:int



func init():
	clear()
	
	
	var setting = Api.get_editor_setting("update_modes",{})



	if not setting:
		for key in Data.keys():
			setting[key] = 0


		Api.set_editor_setting("update_modes", setting)
	else:
		if !setting.keys() == Data.keys():
			for key in Data.keys():
				if not setting.get(key):
					setting[key] = 0
			Api.set_editor_setting("update_modes", setting)

	is_main = name == "Main"

#	modes= Api.get_editor_setting("update_modes", default_modes)
	modes= setting

	dropdown = get_node_or_null("PopupMenu2")
	
	columns = 2

	var root = create_item()
	set_column_titles_visible(true)
	
	
	set_column_title(0, "Parameter")
	if is_main:
		set_column_title(1, "Count")
	if !is_main:
		set_column_title(1, "UpdateMode")
	
#	var data_by_parents

	var parents_items = {}
	for i in parents:
		var item:  = create_item(root)
		item.set_text(0, i)
		parents_items[i] = item
	
	for key in Data:
		key = key as String
		if modes and modes[key] ==1 and is_main: # hide
			continue
			

		var item_info:Array =  Data[key]
		var update_mode:int = item_info[0]
		var parent = item_info[1]
		var item = create_item(parents_items[parent])
#		item.set_text(0, key.capitalize()) # later..
		item.set_text(0, key)



		if is_main:
			var method:String = item_info[2]
			item.set_text(1, str(Api.call(method)))

	
		if !is_main:
			item.set_cell_mode(1, TreeItem.CELL_MODE_CUSTOM)
			item.set_editable(1, true)

			# later change to value from editor
			item.set_text(1, dropdown.get_item_text(modes[key]))

			if modes[key] == 0:
				match update_mode:
					type1:
						item.set_text(1, "Update on popup")
					type2:
						item.set_text(1, "Update ASAP")
			else:
				item.set_text(1, "Don't use")



func _on_custom_popup_edited(arrow_clicked):
	var dropdown:PopupMenu = $PopupMenu2
	
	var key = get_selected().get_text(0)
	var update_mode = Data[key][0]
	if !is_main:
		match update_mode:
			type1:
				dropdown.set_item_text(0, "Update on popup")
			type2:
				dropdown.set_item_text(0, "Update ASAP")

		dropdown.set_item_text(1, "Don't use")



	dropdown.popup(get_custom_popup_rect())


func _on_dropdown_index_pressed(index):
	var dropdown:PopupMenu = $PopupMenu2
	var key = get_selected().get_text(0)
	get_selected().set_text(1,dropdown.get_item_text(index))
	update_mode(key, index)
	


func update_mode(key:String, mode:int):
	modes[key] = mode
	Api.set_editor_setting("update_modes", modes)
	$"../Main".should_update = true

func _on_TabContainer_tab_changed(tab):
	if tab: return
	if should_update:
		init()
		should_update = false
