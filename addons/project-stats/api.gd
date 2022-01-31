tool
extends Resource

const Utils = preload("utils.tres")

const project_metadata_section: = "project_stats"

var res_path: = ProjectSettings.globalize_path("res://")

var plugin:EditorPlugin
var ed_settings:EditorSettings
var scr_ed:ScriptEditor
var filesystem:EditorFileSystem

var recent_textedit:TextEdit
var _need_update_scr_ed_recent_textedit: = true

var coding_timer:Timer
var coding_wait_time = 10

var project_already_opened = false

#this unlikely to work when disabling the plugin by another plugin
#var project_disabled = false

#TODO: make it a separate "behavior"
signal script_text_changed


signal coding_time_changed
signal show_coding_time_setting_changed

signal output_panel_color_changed

func init(plugin:EditorPlugin):
	self.plugin = plugin
	ed_settings = plugin.get_editor_interface().get_editor_settings()

	set_editor_settings()


	scr_ed = plugin.get_editor_interface().get_script_editor()
	if not scr_ed.is_connected("editor_script_changed", self, "on_scr_changed"):
		scr_ed.connect("editor_script_changed", self, "on_scr_changed")
	

	coding_timer = Timer.new()
	coding_timer.wait_time = coding_wait_time
	coding_timer.one_shot = true
	coding_timer.connect("timeout", self, "on_code_timeout")

	var base:Control = plugin.get_editor_interface().get_base_control()
	base.add_child(coding_timer)
	
	var cur_scr:Script = scr_ed.get_current_script()
	if not cur_scr: return
	on_scr_changed(cur_scr)

	filesystem = plugin.get_editor_interface().get_resource_filesystem()
	filesystem.connect("filesystem_changed", self,"on_filesystem")

#
#	if not project_already_opened:
#		increment_setting("opened_times")
#		project_already_opened = true
##		set_meta("ed_settings", ed_settings)
##		set_meta("ed_settings", ed_settings)
		

const output_panel_default_first_color = '#ffeca1'
const output_panel_default_secondary_color = '#6a6d83'


const ed_settings_start = "me2beats_plugins/project_stats/"

func get_editor_setting(key:String, default = null):
	if ed_settings.has_setting(ed_settings_start.plus_file(key)):
		return ed_settings.get_setting(ed_settings_start.plus_file(key))
	else:
		return default


func set_editor_setting(key:String, val):
	ed_settings.set_setting(ed_settings_start.plus_file(key), val)


func set_editor_settings():
	if not ed_settings.has_setting(ed_settings_start.plus_file("show_coding_time_in_output")):
		ed_settings.set_setting(ed_settings_start.plus_file("show_coding_time_in_output"), true)
		ed_settings.set_initial_value(ed_settings_start.plus_file("show_coding_time_in_output"), true, false)
	
	if not ed_settings.has_setting(ed_settings_start.plus_file("output_panel_first_color")):
		ed_settings.set_setting(ed_settings_start.plus_file("output_panel_first_color"), output_panel_default_first_color)
		ed_settings.set_initial_value(ed_settings_start.plus_file("output_panel_first_color"), output_panel_default_first_color, false)

		ed_settings.set_setting(ed_settings_start.plus_file("output_panel_second_color"), output_panel_default_secondary_color)
		ed_settings.set_initial_value(ed_settings_start.plus_file("output_panel_second_color"), output_panel_default_secondary_color, false)
	


func get_setting(key)->int:
	return ed_settings.get_project_metadata(project_metadata_section, key, -1)


func increment_setting(key:String)->int:
	var recent:int = ed_settings.get_project_metadata(project_metadata_section, key, 0)
	ed_settings.set_project_metadata(project_metadata_section, key, recent+1)
	return recent

var files: = []
var filesystem_recent_version: = 0
var filesystem_version: = 0

func on_filesystem():
	filesystem_version+=1
	#we don't update files array here, we do this manually with update_files_cashe()

func quit():
	if is_instance_valid(scr_ed):
		if scr_ed.is_connected("editor_script_changed", self, "on_scr_changed"):
			scr_ed.disconnect("editor_script_changed", self, "on_scr_changed")

	if filesystem:
		filesystem.disconnect("filesystem_changed", self,"on_filesystem")

func on_scr_changed(scr:Script):
	if !_need_update_scr_ed_recent_textedit: return


	var textedit = Utils.get_current_text_ed(scr_ed)
	if not textedit: return
	connect_textedit_changed(textedit, scr)
	

func connect_textedit_changed(text_ed:TextEdit, scr:Script):
	var scr_ed:ScriptEditor = plugin.get_editor_interface().get_script_editor()
	if not text_ed: return

	var signal_ = "text_changed"
	var callback: ="on_script_text_changed"
	

	if is_instance_valid(recent_textedit) and recent_textedit.is_connected(signal_, self, callback):
		recent_textedit.disconnect(signal_, self, callback)
	if not text_ed.is_connected(signal_, self, callback):
		text_ed.connect(signal_, self, callback, [text_ed])



var is_active = false
var recent_time

func on_script_text_changed(text_ed:TextEdit):
	if not is_instance_valid(coding_timer):
		# should disconnect I guess
		return	
#	emit_signal("script_text_changed", text_ed)
	if !coding_timer.is_stopped():
		var recent_coding_time = ed_settings.get_project_metadata(project_metadata_section,"coding_time", 0)
		var new_time = recent_coding_time+coding_wait_time-coding_timer.time_left
		ed_settings.set_project_metadata(project_metadata_section, "coding_time", new_time)
		emit_signal("coding_time_changed")

	coding_timer.start()

func on_code_timeout():
	return




func update_files_cache():
	if ! filesystem_recent_version == filesystem_version or ! files:
		
		
		
		files = Utils.get_files(res_path, true)
		
		# try localized paths
		for i in files.size():
			files[i] = ProjectSettings.localize_path(files[i])
			
		
		filesystem_recent_version = filesystem_version


func get_scenes():
	var files = Utils.get_files_by_ext(res_path, "tscn", true)
	return files



# lets go!

func get_script_count()->int:
	update_files_cache()
	var scripts = Utils.get_files_by_ext(res_path, "gd", true, files)
	return scripts.size()


func get_non_plugin_script_count()->int:
	update_files_cache()
	var count = 0
	var scripts = Utils.get_files_by_ext(res_path, "gd", true, files)
	for path in scripts:
		if path.begins_with("res://addons/"):
			continue
		count+=1
	return count


func get_scene_count()->int:
	update_files_cache()
	var scenes = Utils.get_files_by_ext(res_path, "tscn", true, files)
	return scenes.size()


func get_non_plugin_scene_count():

	update_files_cache()

	var count = 0
	var scenes = Utils.get_files_by_ext(res_path, "tscn", true, files)
	for path in scenes:
		if path.begins_with("res://addons/"):
			continue
		count+=1

	return count


# works only for tscn now!
func get_max_nodes_in_a_scene()->int:
	update_files_cache()
	var scenes = Utils.get_files_by_ext(res_path, "tscn", true, files)	

	var max_nodes: = 0
	for scene_path in scenes:
		var scn:PackedScene = load(scene_path)
		if !is_instance_valid(scn): continue
		var node_count:int = scn._bundled.get("node_count")
		max_nodes = max(max_nodes, node_count)

	return max_nodes


func get_max_nodes_in_non_plugin_scene():

	update_files_cache()
	var scenes = Utils.get_files_by_ext(res_path, "tscn", true, files)	

	var arr =[]
	for s in scenes:
		if !s.begins_with("res://addons/"):
			arr.push_back(s)

	var max_nodes: = 0
	for scene_path in arr:
		var scn:PackedScene = load(scene_path)
		if !is_instance_valid(scn): continue
		var node_count:int = scn._bundled.get("node_count")
		max_nodes = max(max_nodes, node_count)

	return max_nodes

# todo!
func get_total_nodes():
	return 1


# todo allow empty
#warning: can be slow
func get_scripts_total_lines_count()->int:
	update_files_cache()
	var scripts = Utils.get_files_by_ext(res_path, "gd", true, files)
	var total_lines: = 0
	for scr_path in scripts:
		var scr:GDScript = load(scr_path)
		if !is_instance_valid(scr): continue
		var code:String = scr.source_code
		var lines = code.split("\n", true).size()
		total_lines+=lines
	return total_lines


func get_non_plugin_scripts_total_lines_count()->int:
	update_files_cache()
	var scripts = Utils.get_files_by_ext(res_path, "gd", true, files)
	var arr =[]
	for s in scripts:
		if !s.begins_with("res://addons/"):
			arr.push_back(s)

	var total_lines: = 0
	for scr_path in arr:
		var scr:GDScript = load(scr_path)
		if !is_instance_valid(scr): continue
		var code:String = scr.source_code
		var lines = code.split("\n", true).size()
		total_lines+=lines
	return total_lines


func get_coding_time()->int:
	return ed_settings.get_project_metadata(project_metadata_section, "coding_time", 0)


func get_coding_time_readable()->String:
	return Utils.seconds_to_hms(get_coding_time())

func project_opened_times()->int:
	return ed_settings.get_project_metadata(project_metadata_section, "opened_times", 0)

func get_crash_count()->int:
	return get_setting("opened_times")-get_setting("closed_times")

# append_array needed (Godot3.3+? )
func get_editor_nodes_count():
	return Utils.get_nodes(plugin.get_editor_interface().get_base_control()).size()


var f1_pressed_count = 0
func f1_pressed():
	return f1_pressed_count

var ctrl_s_pressed_count = 0
func ctrl_s_pressed():
	return ctrl_s_pressed_count


