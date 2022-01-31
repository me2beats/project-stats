tool
extends Resource

static func find_node_by_class_path(node:Node, class_path:Array)->Node:
	var res:Node

	var stack = []
	var depths = []

	var first = class_path[0]
	for c in node.get_children():
		if c.get_class() == first:
			stack.push_back(c)
			depths.push_back(0)

	if not stack: return res
	
	var max_ = class_path.size()-1

	while stack:
		var d = depths.pop_back()
		var n = stack.pop_back()

		if d>max_:
			continue
		if n.get_class() == class_path[d]:
			if d == max_:
				res = n
				return res

			for c in n.get_children():
				stack.push_back(c)
				depths.push_back(d+1)

	return res





static func get_script_tab_container(scr_ed:ScriptEditor)->TabContainer:
	return find_node_by_class_path(scr_ed, ['VBoxContainer', 'HSplitContainer', 'TabContainer']) as TabContainer



static func get_script_text_editor(scr_ed:ScriptEditor, idx:int)->Container:
	var tab_cont = get_script_tab_container(scr_ed)
	return tab_cont.get_child(idx)


static func get_current_script_idx(scr_ed:ScriptEditor)->int:
	var current = scr_ed.get_current_script()
	var opened = scr_ed.get_open_scripts()
	return opened.find(current)



static func get_code_editor(scr_ed:ScriptEditor, idx:int)->Container:
	var scr_text_ed = get_script_text_editor(scr_ed, idx)
	return find_node_by_class_path(scr_text_ed, ['VSplitContainer', 'CodeTextEditor']) as Container



static func get_text_edit(scr_ed:ScriptEditor, idx:int)->TextEdit:
	var empty:TextEdit
	var code_ed = get_code_editor(scr_ed, idx)
	if not code_ed: return empty
	return find_node_by_class_path(code_ed, ['TextEdit']) as TextEdit

static func get_current_text_ed(scr_ed:ScriptEditor)->TextEdit:
	var idx = get_current_script_idx(scr_ed)
	return get_text_edit(scr_ed, idx)



# buffer



#	var parent = Utils.find_node_by_class_path(
#		base, [
#			'VBoxContainer', 
#			'HSplitContainer',
#			'HSplitContainer',
#			'HSplitContainer',
#			'VBoxContainer',
#			'VSplitContainer',
#			'PanelContainer',
#			'VBoxContainer'
#		]
#	)








var regex: = RegEx.new()


func _init():
	regex.compile("#.*?\\n")


func remove_comments(s:String)->String:
	return regex.sub(s, "", true)

func get_functions_per_line(s:String):
	var lines_with_functions = 0
	var functions = 0
	var lines = s.split("\n")
	for line in  lines:
		line = line as String
		var count = line.count("(")
		if count:
			lines_with_functions+=1
			functions+=count
	return functions/float(lines_with_functions) if functions else 0


# todo: indent char replace
func get_indent_complexity(s:String):
	var lines = s.split("\n")
	var indent_delta = 0
	var nonempty_lines = 0
	var recent_indent = 0
	for line in lines:
		line = line as String
		var indent_char = "	"
		var stripped = line.lstrip(indent_char)
		var indent_count = line.length()-stripped.length()
		if indent_count == recent_indent: continue
		if indent_count ==0 and  recent_indent == 1  or indent_count ==1 and  recent_indent == 0:
			recent_indent =indent_count
			continue

		
		
		
		recent_indent = indent_count
		
		indent_delta+=1
		if stripped:
			nonempty_lines+=1
			
	return indent_delta/float(nonempty_lines) if nonempty_lines else 0



static func remove_all_strings(s:String)->String:
	var result_chars = PoolStringArray()
	var pos = 0
	while pos<s.length() and !pos==-1:
		var ch = s[pos]
		if ch =='"' or ch == "'":
			if ch == '"': #"
				if s[pos+1] == '"': #""
					if s[pos+2] == '"':
						var _pos = s.find('"""', pos+4)
						pos = _pos if _pos == -1 else _pos+3
					else: # one empty string ""
						pos += 2
				else: # "'
					var _pos = s.find('"', pos+2)
					pos = _pos if _pos == -1 else _pos+1
			else:
				if s[pos+1] == "'": #''
					pos += 2
				else: #'"
					var _pos = s.find("'", pos+2)
					pos = _pos if _pos == -1 else _pos+1
		else:
			pos+=1
			result_chars.push_back(ch)
	return result_chars.join("")




# get files non recursively
static func get_files(path:String, recursive=false)->Array:
	if recursive:
		return get_dir_contents(path)[0]

	path = path.trim_suffix("/")
	var dir = Directory.new()
	var res = []
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				res.push_back(path+"/"+file_name)
			file_name = dir.get_next()
	else:
		push_warning(ERROR_MSG)
	return res


#files arg is array of filenames (in case it already exists)
static func get_files_by_ext(dir:String, extension:String, recursive:=false, files: = [])->Array:
	if not files:
		files = get_files(dir, recursive)

	var res = []
	for i in files:
		if i.get_extension() == extension:
			res.push_back(i)
	return res



const ERROR_MSG = "An error occurred when trying to access the path."
# push_warning vs push_error ?

# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
static func get_dir_contents(rootPath: String) -> Array:
	rootPath = rootPath.trim_suffix("/")
	
	var files = []
	var directories = []
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		_add_dir_contents(dir, files, directories)
	else:
		push_warning(ERROR_MSG)

	return [files, directories]
	

static func _add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()

	while file_name != "":
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			_add_dir_contents(subDir, files, directories)
		else:
			files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()




static func seconds_to_hms(seconds:int)->String:
	var m: =  seconds/ 60
	var s: = seconds%60
	var h: = m/60
	m = m%60
	return "%sh:%sm:%ss" % [h, m, s]


static func seconds_to_hms_array(seconds:int)->Array:
	var m: =  seconds/ 60
	var s: = seconds%60
	var h: = m/60
	m = m%60
	return [h,m,s]


# EditorLog utils


static func get_log(base:Control)->VBoxContainer:
	var result: VBoxContainer = find_node_by_class_path(
		base, [
			'VBoxContainer', 
			'HSplitContainer',
			'HSplitContainer',
			'HSplitContainer',
			'VBoxContainer',
			'VSplitContainer',
			'PanelContainer',
			'VBoxContainer',
			'EditorLog'
		]
	)
	return result


static func get_nodes(node:Node)->Array:
	var nodes = []
	var stack = [node]
	while stack:
		var n = stack.pop_back()
		nodes.push_back(n)
		stack.append_array(n.get_children())
	return nodes
